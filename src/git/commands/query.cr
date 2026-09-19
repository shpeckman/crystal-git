# src/git/commands/query.cr
module Git
  module Commands
    class Status < Command
      describe(:status, StateSet::All, nil,
        Predicate::None, Predicate::Bare,
        Predicate::None, Predicate::None,
        Reversibility::ReadOnly)

      def initialize(@flags : StatusFlag)
      end

      def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
        opts = uninitialized LibGit2::StatusOptions
        if err = Git.check(LibGit2.status_options_init(pointerof(opts), 1_u32))
          return err
        end
        opts.show = LibGit2::StatusShow::INDEX_AND_WORKDIR
        opts.flags = @flags.value

        list = uninitialized LibGit2::StatusList
        if err = Git.check(LibGit2.status_list_new(pointerof(list), repo.handle, pointerof(opts)))
          return err
        end

        count   = LibGit2.status_list_entrycount(list)
        entries = Array(StatusEntry).new(count.to_i32)

        count.times do |position|
          entry = LibGit2.status_byindex(list, position)
          next if entry.null?
          delta = entry.value.index_to_workdir
          delta = entry.value.head_to_index if delta.null?
          next if delta.null?
          path = delta.value.new_file.path
          path = delta.value.old_file.path if path.null?
          next if path.null?
          entries << StatusEntry.new(String.new(path), EntryStatus.new(entry.value.status.value))
        end

        LibGit2.status_list_free(list)
        Ok(Value).new(entries)
      end
    end

    class ListBranches < Command
      describe(:list_branches, StateSet::All, nil,
        Predicate::None, Predicate::None,
        Predicate::None, Predicate::None,
        Reversibility::ReadOnly)

      def initialize(@kind : LibGit2::BranchType)
      end

      def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
        iterator = uninitialized LibGit2::BranchIterator
        if err = Git.check(LibGit2.branch_iterator_new(pointerof(iterator), repo.handle, @kind))
          return err
        end

        names = [] of String
        loop do
          ref = uninitialized LibGit2::Reference
          kind = uninitialized LibGit2::BranchType
          result = LibGit2.branch_next(pointerof(ref), pointerof(kind), iterator)
          break if result == LibGit2::ErrorCode::ITEROVER.value

          if result != 0
            failure = Err.capture(result)
            LibGit2.branch_iterator_free(iterator)
            return failure
          end

          name = uninitialized LibC::Char*
          if LibGit2.branch_name(pointerof(name), ref) == 0
            names << String.new(name)
          end
          LibGit2.reference_free(ref)
        end

        LibGit2.branch_iterator_free(iterator)
        Ok(Value).new(names)
      end
    end

    class ListTags < Command
      describe(:list_tags, StateSet::All, nil,
        Predicate::None, Predicate::None,
        Predicate::None, Predicate::None,
        Reversibility::ReadOnly)

      def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
        array = LibGit2::Strarray.new
        if err = Git.check(LibGit2.tag_list(pointerof(array), repo.handle))
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
  end
end
