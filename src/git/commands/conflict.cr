# src/git/commands/conflict.cr
module Git::Commands
  class Conflicts < Command
    describe(:conflicts, StateSet::All, nil,
      Predicate::None, Predicate::Bare,
      Predicate::None, Predicate::None,
      Reversibility::ReadOnly)

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      result = Conflict.list(repo)
      return result if result.is_a?(Err)
      Ok(Value).new(result.value)
    end
  end

  class Resolve < Command
    describe(:resolve, CONFLICT_STATES, nil,
      Predicate::Conflicted, Predicate::Bare,
      Predicate::DirtyIndex, Predicate::None,
      Reversibility::Worktree)

    def initialize(@paths : Array(String), @resolution : Resolution)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      @paths.each do |path|
        if err = Conflict.resolve(repo, path, @resolution)
          return err
        end
      end
      Ok(Value).new(@paths.size)
    end
  end

  class ResolveAll < Command
    describe(:resolve_all, CONFLICT_STATES, nil,
      Predicate::Conflicted, Predicate::Bare,
      Predicate::DirtyIndex, Predicate::Conflicted,
      Reversibility::Worktree)

    def initialize(@resolution : Resolution)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      paths = Conflict.paths(repo)
      return paths if paths.is_a?(Err)

      paths.value.each do |path|
        if err = Conflict.resolve(repo, path, @resolution)
          return err
        end
      end

      Ok(Value).new(paths.value.size)
    end
  end
end
