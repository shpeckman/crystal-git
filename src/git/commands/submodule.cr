# src/git/commands/submodule.cr
module Git::Commands
  class ListSubmodules < Command
    describe(:submodule_list, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::ReadOnly)

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      names = Submodules.names(repo)
      return names if names.is_a?(Err)

      entries = Array(SubmoduleEntry).new(names.value.size)
      names.value.each do |name|
        entry = Submodules.entry(repo, name)
        return entry if entry.is_a?(Err)
        entries << entry.value
      end

      Ok(Value).new(entries)
    end
  end

  class SubmoduleStatus < Command
    describe(:submodule_status, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::ReadOnly)

    def initialize(@name : String)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      entry = Submodules.entry(repo, @name)
      return entry if entry.is_a?(Err)
      Ok(Value).new(entry.value)
    end
  end

  class AddSubmodule < Command
    describe(:submodule_add, CLEAN_ONLY, nil,
      Predicate::None, Predicate::Bare | Predicate::Conflicted,
      Predicate::DirtyIndex, Predicate::None,
      Reversibility::IndexOnly)

    def initialize(@url : String, @path : String, @branch : String?)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      index_record = Undo::IndexTree.capture(repo)
      return index_record if index_record.is_a?(Err)

      workdir = Native.workdir(repo)
      return workdir if workdir.is_a?(Err)
      dotfile = File.join(workdir.value, ".gitmodules")
      prior   = File.file?(dotfile) ? Native.read_bytes(dotfile) : nil

      submodule = uninitialized LibGit2::Submodule
      if err = Git.check(LibGit2.submodule_add_setup(pointerof(submodule), repo.handle, @url, @path, 1))
        return err
      end

      name = Native.text(LibGit2.submodule_name(submodule)) || @path
      undo << Undo::SubmoduleAdd.new(name, @path, prior)
      undo << index_record.value

      opts = uninitialized LibGit2::SubmoduleUpdateOptions
      if err = Git.check(LibGit2.submodule_update_options_init(pointerof(opts), 1_u32))
        LibGit2.submodule_free(submodule)
        return err
      end
      opts.allow_fetch = 1
      opts.checkout_opts = Native.checkout_options(LibGit2::CheckoutStrategy::SAFE.value)

      if credentials = repo.credentials
        session   = Credentials::Session.new(credentials)
        callbacks = opts.fetch_opts.callbacks
        callbacks.credentials = Credentials.callback
        callbacks.payload = Box.box(session)
        opts.fetch_opts.callbacks = callbacks
      end

      child = uninitialized LibGit2::Repository
      result = LibGit2.submodule_clone(pointerof(child), submodule, pointerof(opts))
      if result != 0
        LibGit2.submodule_free(submodule)
        return Err.capture(result)
      end
      LibGit2.repository_free(child)

      if branch = @branch
        if err = Git.check(LibGit2.submodule_set_branch(repo.handle, name, branch))
          LibGit2.submodule_free(submodule)
          return err
        end
      end

      if err = Git.check(LibGit2.submodule_add_finalize(submodule))
        LibGit2.submodule_free(submodule)
        return err
      end

      if err = Git.check(LibGit2.submodule_add_to_index(submodule, 1))
        LibGit2.submodule_free(submodule)
        return err
      end
      LibGit2.submodule_free(submodule)

      index = repo.index
      return index if index.is_a?(Err)
      if err = Git.check(LibGit2.index_add_bypath(index.value, ".gitmodules"))
        return err
      end
      if err = Git.check(LibGit2.index_write(index.value))
        return err
      end

      Ok(Value).new(name)
    end
  end

  class InitSubmodule < Command
    describe(:submodule_init, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::RefOnly)

    def initialize(@name : String, @overwrite : Bool)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      record = Undo::ConfigEntry.capture(repo, "submodule.#{@name}.url")
      return record if record.is_a?(Err)

      submodule = uninitialized LibGit2::Submodule
      if err = Git.check(LibGit2.submodule_lookup(pointerof(submodule), repo.handle, @name))
        return err
      end

      result = LibGit2.submodule_init(submodule, @overwrite ? 1 : 0)
      LibGit2.submodule_free(submodule)
      if err = Git.check(result)
        return err
      end

      undo << record.value
      Ok(Value).new(@name)
    end
  end

  class UpdateSubmodule < Command
    describe(:submodule_update, StateSet::All, nil,
      Predicate::None, Predicate::Bare,
      Predicate::None, Predicate::None,
      Reversibility::RefOnly)

    def initialize(@name : String, @init : Bool)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      submodule = uninitialized LibGit2::Submodule
      if err = Git.check(LibGit2.submodule_lookup(pointerof(submodule), repo.handle, @name))
        return err
      end

      path = Native.text(LibGit2.submodule_path(submodule)) || @name

      status = uninitialized LibC::UInt
      if err = Git.check(LibGit2.submodule_status(pointerof(status), repo.handle, @name, LibGit2::SubmoduleIgnoreType::UNSPECIFIED))
        LibGit2.submodule_free(submodule)
        return err
      end

      initialized = (status & LibGit2::SubmoduleStatus::IN_WD.value) != 0 &&
                    (status & LibGit2::SubmoduleStatus::WD_UNINITIALIZED.value) == 0

      target_ptr = LibGit2.submodule_index_id(submodule)
      head_ptr   = LibGit2.submodule_head_id(submodule)
      prior      = head_ptr.null? ? nil : Oid.from(head_ptr)
      target     = target_ptr.null? ? nil : Oid.from(target_ptr)
      LibGit2.submodule_free(submodule)

      unless initialized
        return Ok(Value).new(@name) unless @init
      end

      undo << Undo::SubmoduleUpdate.new(@name, path, initialized, prior)

      if target.nil? && initialized
        return Ok(Value).new(@name)
      end

      workdir = Native.workdir(repo)
      return workdir if workdir.is_a?(Err)
      location = File.join(workdir.value, path)

      child = nil.as(Repo?)
      begin
        if initialized
          opened = Repo.open(location)
          return opened if opened.is_a?(Err)
          child = opened.value
        else
          url = read_url(repo)
          return url if url.is_a?(Err)
          return Err.invalid("submodule #{@name} has no configured url") unless url.value

          cloned = Repo.clone(url.value.not_nil!, location, credentials: repo.credentials)
          return cloned if cloned.is_a?(Err)
          child = cloned.value
        end

        if err = checkout_target(child.handle, target, repo.credentials)
          return err
        end
      ensure
        child.try(&.close)
      end

      Ok(Value).new(@name)
    end

    private def read_url(repo : Repo) : Ok(String?) | Err
      repo.with_config do |_, config|
        value = uninitialized LibC::Char*
        result = LibGit2.config_get_string(pointerof(value), config, "submodule.#{@name}.url")
        if result == LibGit2::ErrorCode::ENOTFOUND.value
          nil
        elsif err = Git.check(result)
          return err
        else
          String.new(value)
        end
      end
    end

    private def checkout_target(child : LibGit2::Repository, target : Oid?, credentials : Credentials?) : Err?
      oid = target
      return nil unless oid

      raw = oid.raw
      if err = checkout_detached(child, pointerof(raw))
        return err unless err.code.enotfound?
        if err = fetch_origin(child, credentials)
          return err
        end
        return checkout_detached(child, pointerof(raw))
      end
      nil
    end

    private def checkout_detached(child : LibGit2::Repository, oid : LibGit2::Oid*) : Err?
      commit = uninitialized LibGit2::Commit
      if err = Git.check(LibGit2.commit_lookup(pointerof(commit), child, oid))
        return err
      end

      opts    = Native.checkout_options(LibGit2::CheckoutStrategy::FORCE.value)
      failure = Git.check(LibGit2.checkout_tree(child, commit.as(LibGit2::Object), pointerof(opts)))
      LibGit2.commit_free(commit)
      return failure if failure

      Git.check(LibGit2.repository_set_head_detached(child, oid))
    end

    private def fetch_origin(child : LibGit2::Repository, credentials : Credentials?) : Err?
      remote = uninitialized LibGit2::Remote
      if err = Git.check(LibGit2.remote_lookup(pointerof(remote), child, "origin"))
        return err
      end

      opts = uninitialized LibGit2::FetchOptions
      if err = Git.check(LibGit2.fetch_options_init(pointerof(opts), 1_u32))
        LibGit2.remote_free(remote)
        return err
      end

      if credentials
        session   = Credentials::Session.new(credentials)
        callbacks = opts.callbacks
        callbacks.credentials = Credentials.callback
        callbacks.payload = Box.box(session)
        opts.callbacks = callbacks
      end

      result = Git.check(LibGit2.remote_fetch(remote, nil, pointerof(opts), nil))
      LibGit2.remote_free(remote)
      result
    end
  end

  class SyncSubmodules < Command
    describe(:submodule_sync, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::RefOnly)

    def initialize(@name : String?)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      targets = [] of String

      if name = @name
        targets << name
      else
        names = Submodules.names(repo)
        return names if names.is_a?(Err)
        targets = names.value
      end

      return Ok(Value).new(0) if targets.empty?

      gitdir = Native.gitdir(repo)
      return gitdir if gitdir.is_a?(Err)
      workdir = Native.workdir(repo)
      return workdir if workdir.is_a?(Err)

      synced = 0
      targets.each do |name|
        url = effective_url(repo, workdir.value, name)
        return url if url.is_a?(Err)
        value = url.value
        next unless value

        config_path = File.join(gitdir.value, "modules", name, "config")
        next unless File.file?(config_path)

        record = Undo::ConfigEntry.capture(repo, "remote.origin.url", config_path)
        return record if record.is_a?(Err)

        written = repo.with_config(config_path) do |config, _|
          Git.check(LibGit2.config_set_string(config, "remote.origin.url", value))
        end
        return written if written.is_a?(Err)
        if failure = written.value
          return failure
        end

        undo << record.value
        synced += 1
      end

      Ok(Value).new(synced)
    end

    private def effective_url(repo : Repo, workdir : String, name : String) : Ok(String?) | Err
      key  = "submodule.#{name}.url"
      read = repo.with_config { |_, config| read_key(config, key) }
      return read if read.is_a?(Err)
      inner = read.value
      return inner if inner.is_a?(Err)
      return Ok(String?).new(inner.value) if inner.value

      modules_path = File.join(workdir, ".gitmodules")
      return Ok(String?).new(nil) unless File.file?(modules_path)

      fallback = repo.with_config(modules_path) { |_, config| read_key(config, key) }
      return fallback if fallback.is_a?(Err)
      fallback.value
    end

    private def read_key(config : LibGit2::Config, key : String) : Ok(String?) | Err
      value = uninitialized LibC::Char*
      result = LibGit2.config_get_string(pointerof(value), config, key)
      if result == LibGit2::ErrorCode::ENOTFOUND.value
        Ok(String?).new(nil)
      elsif err = Git.check(result)
        err
      else
        Ok(String?).new(String.new(value))
      end
    end
  end
end
