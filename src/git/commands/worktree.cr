# src/git/commands/worktree.cr
require "file_utils"

module Git::Commands
  class ListWorktrees < Command
    describe(:worktree_list, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::ReadOnly)

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      array = LibGit2::Strarray.new
      if err = Git.check(LibGit2.worktree_list(pointerof(array), repo.handle))
        return err
      end

      worktrees = Array(LinkedWorktree).new(array.count.to_i32)
      array.count.times do |position|
        entry = array.strings[position]
        next if entry.null?
        name = String.new(entry)

        worktree = uninitialized LibGit2::Worktree
        next unless LibGit2.worktree_lookup(pointerof(worktree), repo.handle, name) == 0

        path = Native.text(LibGit2.worktree_path(worktree)) || ""
        worktrees << LinkedWorktree.new(name, path, LibGit2.worktree_is_locked(nil, worktree) == 1)
        LibGit2.worktree_free(worktree)
      end

      LibGit2.strarray_dispose(pointerof(array))
      Ok(Value).new(worktrees)
    end
  end

  class AddWorktree < Command
    describe(:worktree_add, StateSet::All, nil,
      Predicate::None, Predicate::Conflicted,
      Predicate::None, Predicate::None,
      Reversibility::RefOnly)

    def initialize(@name : String, @path : String, @ref : String?)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      opts = uninitialized LibGit2::WorktreeAddOptions
      if err = Git.check(LibGit2.worktree_add_options_init(pointerof(opts), 1_u32))
        return err
      end

      if ref = @ref
        reference = uninitialized LibGit2::Reference
        if err = Git.check(LibGit2.reference_dwim(pointerof(reference), repo.handle, ref))
          return err
        end
        opts.ref = reference
      end

      worktree = uninitialized LibGit2::Worktree
      result = LibGit2.worktree_add(pointerof(worktree), repo.handle, @name, @path, pointerof(opts))
      LibGit2.reference_free(opts.ref) unless opts.ref.null?
      if err = Git.check(result)
        return err
      end
      LibGit2.worktree_free(worktree)

      undo << Undo::WorktreeAdd.new(@name, @path)
      Ok(Value).new(@path)
    end
  end

  class RemoveWorktree < Command
    describe(:worktree_remove, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::External)

    def initialize(@name : String, @force : Bool)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      worktree = uninitialized LibGit2::Worktree
      if err = Git.check(LibGit2.worktree_lookup(pointerof(worktree), repo.handle, @name))
        return err
      end

      unless @force
        if LibGit2.worktree_is_locked(nil, worktree) == 1
          LibGit2.worktree_free(worktree)
          return Err.invalid("worktree #{@name} is locked; remove it with force: true")
        end

        path = Native.text(LibGit2.worktree_path(worktree))
        if path && dirty?(path)
          LibGit2.worktree_free(worktree)
          return Err.invalid("worktree #{@name} has pending changes; remove it with force: true")
        end
      end

      location = Native.text(LibGit2.worktree_path(worktree))
      opts = uninitialized LibGit2::WorktreePruneOptions
      LibGit2.worktree_prune_options_init(pointerof(opts), 1_u32)
      opts.flags = LibGit2::WorktreePruneType::VALID.value |
                   LibGit2::WorktreePruneType::LOCKED.value |
                   LibGit2::WorktreePruneType::WORKING_TREE.value

      result = LibGit2.worktree_prune(worktree, pointerof(opts))
      LibGit2.worktree_free(worktree)
      if err = Git.check(result)
        return err
      end

      FileUtils.rm_rf(location) if location
      Ok(Value).new(@name)
    end

    private def dirty?(path : String) : Bool
      handle = uninitialized LibGit2::Repository
      return false unless LibGit2.repository_open_ext(pointerof(handle), path, 0_u32, nil) == 0

      opts = uninitialized LibGit2::StatusOptions
      LibGit2.status_options_init(pointerof(opts), 1_u32)
      opts.flags = LibGit2::StatusOpt::INCLUDE_UNTRACKED.value |
                   LibGit2::StatusOpt::RECURSE_UNTRACKED_DIRS.value

      dirty = false
      list = uninitialized LibGit2::StatusList
      if LibGit2.status_list_new(pointerof(list), handle, pointerof(opts)) == 0
        dirty = LibGit2.status_list_entrycount(list) > 0
        LibGit2.status_list_free(list)
      end

      LibGit2.repository_free(handle)
      dirty
    end
  end

  class PruneWorktrees < Command
    describe(:worktree_prune, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::External)

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      array = LibGit2::Strarray.new
      if err = Git.check(LibGit2.worktree_list(pointerof(array), repo.handle))
        return err
      end

      opts = uninitialized LibGit2::WorktreePruneOptions
      LibGit2.worktree_prune_options_init(pointerof(opts), 1_u32)

      pruned  = 0
      failure = nil.as(Err?)

      array.count.times do |position|
        entry = array.strings[position]
        next if entry.null?

        worktree = uninitialized LibGit2::Worktree
        next unless LibGit2.worktree_lookup(pointerof(worktree), repo.handle, entry) == 0

        if LibGit2.worktree_is_prunable(worktree, pointerof(opts)) == 1
          result = LibGit2.worktree_prune(worktree, pointerof(opts))
          if result == 0
            pruned += 1
          else
            failure ||= Err.capture(result)
          end
        end
        LibGit2.worktree_free(worktree)
      end

      LibGit2.strarray_dispose(pointerof(array))
      return failure if failure
      Ok(Value).new(pruned)
    end
  end
end
