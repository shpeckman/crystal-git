# src/git/commands/apply.cr
module Git::Commands
  class ApplyPatch < Command
    describe(:apply, StateSet::All, nil,
      Predicate::None, Predicate::Bare | Predicate::Conflicted,
      Predicate::None, Predicate::None,
      Reversibility::Worktree)

    def initialize(@patch : String, @location : ApplyLocation)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      diff = uninitialized LibGit2::Diff
      if err = Git.check(LibGit2.diff_from_buffer(pointerof(diff), @patch, @patch.bytesize.to_u64))
        return err
      end

      applied = LibGit2.diff_num_deltas(diff).to_i32
      result  = LibGit2.apply(repo.handle, diff, @location.to_native, Pointer(LibGit2::ApplyOptions).null)
      LibGit2.diff_free(diff)

      if err = Git.check(result)
        return err
      end
      if @location.index? || @location.both?
        if err = repo.reload_index
          return err
        end
      end
      Ok(Value).new(applied)
    end
  end
end
