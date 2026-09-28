# src/git/commands/remote.cr
module Git::Commands
  class RemoteAdd < Command
    describe(:remote_add, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::RefOnly)

    def initialize(@name : String, @url : String)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      remote = uninitialized LibGit2::Remote
      if err = Git.check(LibGit2.remote_create(pointerof(remote), repo.handle, @name, @url))
        return err
      end
      LibGit2.remote_free(remote)

      undo << Undo::RemoteAdd.new(@name)
      Ok(Value).new(@name)
    end
  end

  class RemoteRemove < Command
    describe(:remote_remove, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::RefOnly)

    def initialize(@name : String)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      remote = uninitialized LibGit2::Remote
      if err = Git.check(LibGit2.remote_lookup(pointerof(remote), repo.handle, @name))
        return err
      end

      url = Native.text(LibGit2.remote_url(remote))
      LibGit2.remote_free(remote)

      if err = Git.check(LibGit2.remote_delete(repo.handle, @name))
        return err
      end

      undo << Undo::RemoteRemove.new(@name, url)
      Ok(Value).new(@name)
    end
  end

  class RemoteList < Command
    describe(:remote_list, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::ReadOnly)

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      array = LibGit2::Strarray.new
      if err = Git.check(LibGit2.remote_list(pointerof(array), repo.handle))
        return err
      end

      names = Array(String).new(array.count.to_i32)
      array.count.times do |position|
        entry = array.strings[position]
        names << String.new(entry) unless entry.null?
      end

      LibGit2.strarray_dispose(pointerof(array))
      Ok(Value).new(names)
    end
  end

  class Fetch < Command
    describe(:fetch, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::External)

    def initialize(@remote : String, @refspecs : Array(String), @prune : Prune, @credentials : Credentials?)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      remote = uninitialized LibGit2::Remote
      if err = Git.check(LibGit2.remote_lookup(pointerof(remote), repo.handle, @remote))
        return err
      end

      opts = uninitialized LibGit2::FetchOptions
      if err = Git.check(LibGit2.fetch_options_init(pointerof(opts), 1_u32))
        LibGit2.remote_free(remote)
        return err
      end
      opts.prune = @prune.to_native

      credentials = @credentials || repo.credentials
      session     = credentials ? Credentials::Session.new(credentials) : nil
      boxed       = session ? Box.box(session) : Pointer(Void).null

      if session
        callbacks = opts.callbacks
        callbacks.credentials = Credentials.callback
        callbacks.payload = boxed
        opts.callbacks = callbacks
      end

      failure = if @refspecs.empty?
                  Git.check(LibGit2.remote_fetch(remote, nil, pointerof(opts), nil))
                else
                  Native.strarray(@refspecs) do |array|
                    Git.check(LibGit2.remote_fetch(remote, array, pointerof(opts), nil))
                  end
                end

      LibGit2.remote_free(remote)
      return failure if failure
      Ok(Value).new(@remote)
    end
  end

  class Push < Command
    describe(:push, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::External)

    def initialize(@remote : String, @refspecs : Array(String), @credentials : Credentials?)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      remote = uninitialized LibGit2::Remote
      if err = Git.check(LibGit2.remote_lookup(pointerof(remote), repo.handle, @remote))
        return err
      end

      opts = uninitialized LibGit2::PushOptions
      if err = Git.check(LibGit2.push_options_init(pointerof(opts), 1_u32))
        LibGit2.remote_free(remote)
        return err
      end

      credentials = @credentials || repo.credentials
      session     = credentials ? Credentials::Session.new(credentials) : nil
      boxed       = session ? Box.box(session) : Pointer(Void).null

      if session
        callbacks = opts.callbacks
        callbacks.credentials = Credentials.callback
        callbacks.payload = boxed
        opts.callbacks = callbacks
      end

      failure = if @refspecs.empty?
                  Git.check(LibGit2.remote_push(remote, nil, pointerof(opts)))
                else
                  Native.strarray(@refspecs) do |array|
                    Git.check(LibGit2.remote_push(remote, array, pointerof(opts)))
                  end
                end

      LibGit2.remote_free(remote)
      return failure if failure
      Ok(Value).new(@remote)
    end
  end
end
