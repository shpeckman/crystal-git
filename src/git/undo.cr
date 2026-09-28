# src/git/undo.cr
require "file_utils"

module Git
  abstract class Undo
    abstract def apply(repo : Repo) : Err?

    def intent : RefIntent?
      nil
    end

    def self.position(repo : Repo) : Ok(Undo) | Err
      handle = repo.handle

      if LibGit2.repository_head_unborn(handle) == 1
        name = repo.head_symbolic_name
        return name if name.is_a?(Err)
        return Ok(Undo).new(Ref.new(name.value, nil, false))
      end

      if LibGit2.repository_head_detached(handle) == 1
        oid = repo.head_oid
        return oid if oid.is_a?(Err)
        return Ok(Undo).new(Head.new(nil, oid.value))
      end

      ref = uninitialized LibGit2::Reference
      if err = Git.check(LibGit2.repository_head(pointerof(ref), handle))
        return err
      end
      name   = String.new(LibGit2.reference_name(ref))
      target = LibGit2.reference_target(ref)
      oid    = target.null? ? nil : Oid.from(target)
      LibGit2.reference_free(ref)
      Ok(Undo).new(Ref.new(name, oid, true))
    end

    def self.attachment(repo : Repo) : Ok(Undo) | Err
      ref = uninitialized LibGit2::Reference
      if err = Git.check(LibGit2.reference_lookup(pointerof(ref), repo.handle, "HEAD"))
        return err
      end
      symbolic = LibGit2.reference_symbolic_target(ref)
      if symbolic.null?
        target = LibGit2.reference_target(ref)
        oid    = target.null? ? nil : Oid.from(target)
        LibGit2.reference_free(ref)
        return Ok(Undo).new(Head.new(nil, oid))
      end
      name = String.new(symbolic)
      LibGit2.reference_free(ref)
      Ok(Undo).new(Head.new(name, nil))
    end
  end

  class Undo::Ref < Undo
    def initialize(@name : String, @target : Oid?, @existed : Bool)
    end

    def intent : RefIntent?
      RefIntent.new(@name, @existed ? @target : nil)
    end

    def apply(repo : Repo) : Err?
      record = intent
      return nil unless record
      RefTransaction.write(repo, record)
    end
  end

  class Undo::Head < Undo
    def initialize(@symbolic : String?, @detached : Oid?)
    end

    def apply(repo : Repo) : Err?
      if symbolic = @symbolic
        return Git.check(LibGit2.repository_set_head(repo.handle, symbolic))
      end
      if detached = @detached
        raw = detached.raw
        return Git.check(LibGit2.repository_set_head_detached(repo.handle, pointerof(raw)))
      end
      nil
    end
  end

  class Undo::IndexTree < Undo
    def self.capture(repo : Repo) : Ok(Undo) | Err
      index = repo.index
      return index if index.is_a?(Err)
      oid = uninitialized LibGit2::Oid
      if err = Git.check(LibGit2.index_write_tree_to(pointerof(oid), index.value, repo.handle))
        return err
      end
      Ok(Undo).new(new(Oid.new(oid)))
    end

    def initialize(@tree : Oid)
    end

    def apply(repo : Repo) : Err?
      index = repo.index
      return index if index.is_a?(Err)
      handle = index.value

      raw = @tree.raw
      tree = uninitialized LibGit2::Tree
      if err = Git.check(LibGit2.tree_lookup(pointerof(tree), repo.handle, pointerof(raw)))
        return err
      end
      failure = Git.check(LibGit2.index_read_tree(handle, tree))
      LibGit2.tree_free(tree)
      return failure if failure
      Git.check(LibGit2.index_write(handle))
    end
  end

  class Undo::StateCleanup < Undo
    def apply(repo : Repo) : Err?
      Git.check(LibGit2.repository_state_cleanup(repo.handle))
    end
  end

  class Undo::RebaseAbort < Undo
    def apply(repo : Repo) : Err?
      rebase = uninitialized LibGit2::Rebase
      return nil unless LibGit2.rebase_open(pointerof(rebase), repo.handle, nil) == 0
      result = Git.check(LibGit2.rebase_abort(rebase))
      LibGit2.rebase_free(rebase)
      result
    end
  end

  class Undo::StashDrop < Undo
    def initialize(@oid : Oid)
    end

    def apply(repo : Repo) : Err?
      position = Stash.locate(repo, @oid)
      return nil unless position
      Git.check(LibGit2.stash_drop(repo.handle, position.to_u64))
    end
  end

  class Undo::Upstream < Undo
    def self.capture(repo : Repo, branch : String) : Ok(Undo) | Err
      ref = uninitialized LibGit2::Reference
      if err = Git.check(LibGit2.branch_lookup(pointerof(ref), repo.handle, branch, LibGit2::BranchType::LOCAL))
        return err
      end

      upstream = uninitialized LibGit2::Reference
      current = nil.as(String?)
      if LibGit2.branch_upstream(pointerof(upstream), ref) == 0
        current = Native.text(LibGit2.reference_shorthand(upstream))
        LibGit2.reference_free(upstream)
      end
      LibGit2.reference_free(ref)

      Ok(Undo).new(new(branch, current))
    end

    def initialize(@branch : String, @upstream : String?)
    end

    def apply(repo : Repo) : Err?
      ref = uninitialized LibGit2::Reference
      if err = Git.check(LibGit2.branch_lookup(pointerof(ref), repo.handle, @branch, LibGit2::BranchType::LOCAL))
        return err
      end
      result = Git.check(LibGit2.branch_set_upstream(ref, Native.pointer(@upstream)))
      LibGit2.reference_free(ref)
      result
    end
  end

  class Undo::ConfigEntry < Undo
    def self.capture(repo : Repo, name : String, config_path : String? = nil) : Ok(Undo) | Err
      read = repo.with_config(config_path) do |_, config|
        value = uninitialized LibC::Char*
        result = LibGit2.config_get_string(pointerof(value), config, name)
        unless result == 0 || result == LibGit2::ErrorCode::ENOTFOUND.value
          return Err.capture(result)
        end
        result == 0 ? String.new(value) : nil
      end
      return read if read.is_a?(Err)
      Ok(Undo).new(new(name, read.value, config_path))
    end

    def initialize(@name : String, @prior : String?, @config_path : String? = nil)
    end

    def apply(repo : Repo) : Err?
      applied = repo.with_config(@config_path) do |config, _|
        if prior = @prior
          Git.check(LibGit2.config_set_string(config, @name, prior))
        else
          result = LibGit2.config_delete_entry(config, @name)
          result == LibGit2::ErrorCode::ENOTFOUND.value ? nil : Git.check(result)
        end
      end
      return applied if applied.is_a?(Err)
      applied.value
    end
  end

  class Undo::RemoteAdd < Undo
    def initialize(@name : String)
    end

    def apply(repo : Repo) : Err?
      result = LibGit2.remote_delete(repo.handle, @name)
      return nil if result == LibGit2::ErrorCode::ENOTFOUND.value
      Git.check(result)
    end
  end

  class Undo::RemoteRemove < Undo
    def initialize(@name : String, @url : String?)
    end

    def apply(repo : Repo) : Err?
      url = @url
      return nil unless url
      remote = uninitialized LibGit2::Remote
      if err = Git.check(LibGit2.remote_create(pointerof(remote), repo.handle, @name, url))
        return err
      end
      LibGit2.remote_free(remote)
      nil
    end
  end

  class Undo::RemoteSetUrl < Undo
    def initialize(@name : String, @prior : String)
    end

    def apply(repo : Repo) : Err?
      Git.check(LibGit2.remote_set_url(repo.handle, @name, @prior))
    end
  end

  class Undo::RemoteRename < Undo
    def initialize(@current : String, @prior : String)
    end

    def apply(repo : Repo) : Err?
      problems = LibGit2::Strarray.new
      result   = Git.check(LibGit2.remote_rename(pointerof(problems), repo.handle, @current, @prior))
      LibGit2.strarray_dispose(pointerof(problems))
      result
    end
  end

  class Undo::NoteSet < Undo
    def initialize(@ref : String?, @object : Oid, @prior : String?)
    end

    def apply(repo : Repo) : Err?
      signature = repo.signature
      return signature if signature.is_a?(Err)

      raw = @object.raw
      if prior = @prior
        created = uninitialized LibGit2::Oid
        Git.check(LibGit2.note_create(pointerof(created), repo.handle, Native.pointer(@ref),
          signature.value, signature.value, pointerof(raw), prior, 1))
      else
        Git.check(LibGit2.note_remove(repo.handle, Native.pointer(@ref),
          signature.value, signature.value, pointerof(raw)))
      end
    end
  end

  class Undo::WorktreeAdd < Undo
    def initialize(@name : String, @path : String)
    end

    def apply(repo : Repo) : Err?
      FileUtils.rm_rf(@path)

      worktree = uninitialized LibGit2::Worktree
      return nil unless LibGit2.worktree_lookup(pointerof(worktree), repo.handle, @name) == 0

      opts = uninitialized LibGit2::WorktreePruneOptions
      LibGit2.worktree_prune_options_init(pointerof(opts), 1_u32)
      opts.flags = LibGit2::WorktreePruneType::VALID.value | LibGit2::WorktreePruneType::LOCKED.value

      result = Git.check(LibGit2.worktree_prune(worktree, pointerof(opts)))
      LibGit2.worktree_free(worktree)
      result
    end
  end

  class Undo::SubmoduleAdd < Undo
    def initialize(@name : String, @path : String, @gitmodules : Bytes?)
    end

    def apply(repo : Repo) : Err?
      cleaned = repo.with_config do |config, _|
        {"url", "branch", "active"}.each do |key|
          LibGit2.config_delete_entry(config, "submodule.#{@name}.#{key}")
        end
        nil
      end
      return cleaned if cleaned.is_a?(Err)

      workdir = Native.workdir(repo)
      return workdir if workdir.is_a?(Err)

      gitmodules = File.join(workdir.value, ".gitmodules")
      if prior = @gitmodules
        Native.write_bytes(gitmodules, prior)
      else
        File.delete(gitmodules) if File.exists?(gitmodules)
      end

      FileUtils.rm_rf(File.join(workdir.value, @path))

      gitdir = Native.gitdir(repo)
      return gitdir if gitdir.is_a?(Err)
      FileUtils.rm_rf(File.join(gitdir.value, "modules", @name))
      nil
    end
  end

  class Undo::SubmoduleUpdate < Undo
    def initialize(@name : String, @path : String, @was_initialized : Bool, @prior_head : Oid?)
    end

    def apply(repo : Repo) : Err?
      workdir = Native.workdir(repo)
      return workdir if workdir.is_a?(Err)
      location = File.join(workdir.value, @path)

      unless @was_initialized
        cleaned = repo.with_config do |config, _|
          LibGit2.config_delete_entry(config, "submodule.#{@name}.url")
          nil
        end
        return cleaned if cleaned.is_a?(Err)

        gitdir = Native.gitdir(repo)
        return gitdir if gitdir.is_a?(Err)
        FileUtils.rm_rf(File.join(gitdir.value, "modules", @name))
        FileUtils.rm_rf(location)
        return nil
      end

      prior = @prior_head
      return nil unless prior

      handle = uninitialized LibGit2::Repository
      if err = Git.check(LibGit2.repository_open_ext(pointerof(handle), location, 0_u32, nil))
        return err
      end

      raw = prior.raw
      annotated = uninitialized LibGit2::AnnotatedCommit
      failure = Git.check(LibGit2.annotated_commit_lookup(pointerof(annotated), handle, pointerof(raw)))
      unless failure
        opts    = Native.checkout_options(LibGit2::CheckoutStrategy::FORCE.value)
        failure = Git.check(LibGit2.reset_from_annotated(handle, annotated, LibGit2::ResetType::HARD, pointerof(opts)))
        LibGit2.annotated_commit_free(annotated)
      end
      LibGit2.repository_free(handle)
      failure
    end
  end
end
