# src/git/commands/stash.cr
module Git::Commands
  class Save < Command
    describe(:stash, CLEAN_ONLY, nil,
      Predicate::DirtyIndex, Predicate::Bare | Predicate::UnbornHead | Predicate::Conflicted,
      Predicate::None, Predicate::DirtyIndex,
      Reversibility::Worktree)

    def initialize(@message : String?, @flags : StashFlag)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      signature = repo.signature
      return signature if signature.is_a?(Err)

      opts = uninitialized LibGit2::StashSaveOptions
      if err = Git.check(LibGit2.stash_save_options_init(pointerof(opts), 1_u32))
        return err
      end
      opts.flags = @flags.value
      opts.stasher = signature.value
      opts.message = Native.pointer(@message)

      created = uninitialized LibGit2::Oid
      if err = Git.check(LibGit2.stash_save_with_opts(pointerof(created), repo.handle, pointerof(opts)))
        return err
      end

      oid = Oid.new(created)
      undo << Undo::StashDrop.new(oid)

      if err = repo.reload_index
        return err
      end
      Ok(Value).new(oid)
    end
  end

  class Apply < Command
    describe(:stash_apply, CLEAN_ONLY, nil,
      Predicate::None, Predicate::Bare | Predicate::Conflicted,
      Predicate::DirtyIndex, Predicate::None,
      Reversibility::Worktree)

    def initialize(@position : Int32, @flags : StashApplyFlag)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      opts = uninitialized LibGit2::StashApplyOptions
      if err = Git.check(LibGit2.stash_apply_options_init(pointerof(opts), 1_u32))
        return err
      end
      opts.flags = @flags.value

      if err = Git.check(LibGit2.stash_apply(repo.handle, @position.to_u64, pointerof(opts)))
        return err
      end
      if err = repo.reload_index
        return err
      end
      Ok(Value).new(@position)
    end
  end

  class Pop < Command
    describe(:stash_pop, CLEAN_ONLY, nil,
      Predicate::None, Predicate::Bare | Predicate::Conflicted,
      Predicate::DirtyIndex, Predicate::None,
      Reversibility::External)

    def initialize(@position : Int32, @flags : StashApplyFlag)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      opts = uninitialized LibGit2::StashApplyOptions
      if err = Git.check(LibGit2.stash_apply_options_init(pointerof(opts), 1_u32))
        return err
      end
      opts.flags = @flags.value

      if err = Git.check(LibGit2.stash_pop(repo.handle, @position.to_u64, pointerof(opts)))
        return err
      end
      if err = repo.reload_index
        return err
      end
      Ok(Value).new(@position)
    end
  end

  class Drop < Command
    describe(:stash_drop, StateSet::All, nil,
      Predicate::None, Predicate::Bare,
      Predicate::None, Predicate::None,
      Reversibility::External)

    def initialize(@position : Int32)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      if err = Git.check(LibGit2.stash_drop(repo.handle, @position.to_u64))
        return err
      end
      Ok(Value).new(@position)
    end
  end

  class ListStash < Command
    describe(:stash_list, StateSet::All, nil,
      Predicate::None, Predicate::Bare,
      Predicate::None, Predicate::None,
      Reversibility::ReadOnly)

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      result = Stash.list(repo)
      return result if result.is_a?(Err)
      Ok(Value).new(result.value)
    end
  end
end
