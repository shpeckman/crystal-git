# src/git/commands/index.cr
module Git::Commands
  class Stage < Command
    describe(:stage, MUTABLE_STATES, nil,
      Predicate::None, Predicate::Bare,
      Predicate::DirtyIndex, Predicate::None,
      Reversibility::IndexOnly)

    def initialize(@pathspec : Array(String), @flags : StageFlag)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      record = Undo::IndexTree.capture(repo)
      return record if record.is_a?(Err)
      undo << record.value

      result = repo.index
      return result if result.is_a?(Err)
      handle = result.value

      failure = Native.strarray(@pathspec) do |array|
        Git.check(LibGit2.index_add_all(handle, array, @flags.value, nil, nil))
      end
      return failure if failure

      if err = Git.check(LibGit2.index_write(handle))
        return err
      end
      Ok(Value).new(LibGit2.index_entrycount(handle))
    end
  end

  class Unstage < Command
    describe(:unstage, MUTABLE_STATES, nil,
      Predicate::None, Predicate::Bare | Predicate::UnbornHead,
      Predicate::None, Predicate::None,
      Reversibility::IndexOnly)

    def initialize(@pathspec : Array(String))
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      record = Undo::IndexTree.capture(repo)
      return record if record.is_a?(Err)
      undo << record.value

      object = uninitialized LibGit2::Object
      if err = Git.check(LibGit2.revparse_single(pointerof(object), repo.handle, "HEAD"))
        return err
      end

      failure = Native.strarray(@pathspec) do |array|
        Git.check(LibGit2.reset_default(repo.handle, object, array))
      end
      Native.free_object(object)
      return failure if failure

      if err = repo.reload_index
        return err
      end
      Ok(Value).new(@pathspec.size)
    end
  end

  class Remove < Command
    describe(:remove, MUTABLE_STATES, nil,
      Predicate::None, Predicate::Bare,
      Predicate::DirtyIndex, Predicate::None,
      Reversibility::Worktree)

    def initialize(@pathspec : Array(String))
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      record = Undo::IndexTree.capture(repo)
      return record if record.is_a?(Err)
      undo << record.value

      result = repo.index
      return result if result.is_a?(Err)
      handle = result.value

      matched = [] of String
      boxed   = Box.box(matched)

      failure = Native.strarray(@pathspec) do |array|
        Git.check(LibGit2.index_remove_all(handle, array, ->(path : LibC::Char*, spec : LibC::Char*, payload : Void*) {
          collected = Box(Array(String)).unbox(payload)
          collected << String.new(path) unless path.null?
          0
        }, boxed))
      end
      return failure if failure

      if workdir = Native.text(LibGit2.repository_workdir(repo.handle))
        matched.each do |path|
          full = File.join(workdir, path)
          File.delete(full) if File.exists?(full)
        end
      end

      if err = Git.check(LibGit2.index_write(handle))
        return err
      end

      Ok(Value).new(matched.size.to_u64)
    end
  end
end
