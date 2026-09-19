# src/git/commands/integrate.cr
module Git
  module Commands
    class Merge < Command
      describe(:merge, CLEAN_ONLY, State::Merge,
        Predicate::None, Predicate::Bare | Predicate::Conflicted | Predicate::DirtyIndex,
        Predicate::None, Predicate::None,
        Reversibility::Worktree)

      def initialize(@target : String, @flags : MergeFlag)
      end

      def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
        record = Undo.position(repo)
        return record if record.is_a?(Err)
        undo << record.value
        undo << Undo::StateCleanup.new

        resolved = Native.annotated(repo, @target)
        return resolved if resolved.is_a?(Err)
        annotated = resolved.value

        heads = uninitialized LibGit2::AnnotatedCommit[1]
        heads[0] = annotated

        analysis = uninitialized LibGit2::MergeAnalysis
        preference = uninitialized LibGit2::MergePreference
        if err = Git.check(LibGit2.merge_analysis(pointerof(analysis), pointerof(preference), repo.handle, heads.to_unsafe, 1_u64))
          LibGit2.annotated_commit_free(annotated)
          return err
        end

        if analysis.value & LibGit2::MergeAnalysis::UP_TO_DATE.value != 0
          LibGit2.annotated_commit_free(annotated)
          return Ok(Value).new(MergeOutcome::UpToDate)
        end

        forwardable = analysis.value & LibGit2::MergeAnalysis::FASTFORWARD.value != 0
        refused     = preference.value & LibGit2::MergePreference::NO_FASTFORWARD.value != 0

        if forwardable && !refused
          oid     = Oid.from(LibGit2.annotated_commit_id(annotated))
          failure = fast_forward(repo, oid)
          LibGit2.annotated_commit_free(annotated)
          return failure if failure
          return Ok(Value).new(MergeOutcome::FastForward)
        end

        merge_opts    = Native.merge_options(@flags.value)
        checkout_opts = Native.checkout_options(LibGit2::CheckoutStrategy::SAFE.value)
        result        = Git.check(LibGit2.merge(repo.handle, heads.to_unsafe, 1_u64, pointerof(merge_opts), pointerof(checkout_opts)))
        LibGit2.annotated_commit_free(annotated)
        return result if result

        if err = repo.reload_index
          return err
        end

        index = repo.index
        return index if index.is_a?(Err)

        conflicted = LibGit2.index_has_conflicts(index.value) == 1
        Ok(Value).new(conflicted ? MergeOutcome::Conflicted : MergeOutcome::Merged)
      end

      private def fast_forward(repo : Repo, oid : Oid) : Err?
        raw = oid.raw
        commit = uninitialized LibGit2::Commit
        if err = Git.check(LibGit2.commit_lookup(pointerof(commit), repo.handle, pointerof(raw)))
          return err
        end

        opts    = Native.checkout_options(LibGit2::CheckoutStrategy::SAFE.value)
        failure = Git.check(LibGit2.checkout_tree(repo.handle, commit.as(LibGit2::Object), pointerof(opts)))
        LibGit2.commit_free(commit)
        return failure if failure

        if LibGit2.repository_head_unborn(repo.handle) == 1
          name = repo.head_symbolic_name
          return name if name.is_a?(Err)
          created = uninitialized LibGit2::Reference
          if err = Git.check(LibGit2.reference_create(pointerof(created), repo.handle, name.value, pointerof(raw), 1, "merge: fast-forward"))
            return err
          end
          LibGit2.reference_free(created)
          return repo.reload_index
        end

        ref = uninitialized LibGit2::Reference
        if err = Git.check(LibGit2.repository_head(pointerof(ref), repo.handle))
          return err
        end
        moved = uninitialized LibGit2::Reference
        result = Git.check(LibGit2.reference_set_target(pointerof(moved), ref, pointerof(raw), "merge: fast-forward"))
        LibGit2.reference_free(ref)
        return result if result
        LibGit2.reference_free(moved)
        repo.reload_index
      end
    end

    class CherryPick < Command
      describe(:cherry_pick, CLEAN_ONLY, State::Cherrypick,
        Predicate::None, Predicate::Bare | Predicate::Conflicted | Predicate::DirtyIndex,
        Predicate::None, Predicate::None,
        Reversibility::Worktree)

      def initialize(@target : String, @mainline : UInt32, @flags : MergeFlag)
      end

      def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
        record = Undo.position(repo)
        return record if record.is_a?(Err)
        undo << record.value
        undo << Undo::StateCleanup.new

        lookup = Native.commit(repo, @target)
        return lookup if lookup.is_a?(Err)
        commit = lookup.value
        oid    = Oid.from(LibGit2.commit_id(commit))

        opts = uninitialized LibGit2::CherrypickOptions
        if err = Git.check(LibGit2.cherrypick_options_init(pointerof(opts), 1_u32))
          LibGit2.commit_free(commit)
          return err
        end
        opts.mainline = @mainline
        opts.merge_opts = Native.merge_options(@flags.value)
        opts.checkout_opts = Native.checkout_options(LibGit2::CheckoutStrategy::SAFE.value)

        result = Git.check(LibGit2.cherrypick(repo.handle, commit, pointerof(opts)))
        LibGit2.commit_free(commit)
        return result if result

        if err = repo.reload_index
          return err
        end
        Ok(Value).new(oid)
      end
    end

    class Revert < Command
      describe(:revert, CLEAN_ONLY, State::Revert,
        Predicate::None, Predicate::Bare | Predicate::Conflicted | Predicate::DirtyIndex,
        Predicate::None, Predicate::None,
        Reversibility::Worktree)

      def initialize(@target : String, @mainline : UInt32, @flags : MergeFlag)
      end

      def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
        record = Undo.position(repo)
        return record if record.is_a?(Err)
        undo << record.value
        undo << Undo::StateCleanup.new

        lookup = Native.commit(repo, @target)
        return lookup if lookup.is_a?(Err)
        commit = lookup.value
        oid    = Oid.from(LibGit2.commit_id(commit))

        opts = uninitialized LibGit2::RevertOptions
        if err = Git.check(LibGit2.revert_options_init(pointerof(opts), 1_u32))
          LibGit2.commit_free(commit)
          return err
        end
        opts.mainline = @mainline
        opts.merge_opts = Native.merge_options(@flags.value)
        opts.checkout_opts = Native.checkout_options(LibGit2::CheckoutStrategy::SAFE.value)

        result = Git.check(LibGit2.revert(repo.handle, commit, pointerof(opts)))
        LibGit2.commit_free(commit)
        return result if result

        if err = repo.reload_index
          return err
        end
        Ok(Value).new(oid)
      end
    end

    class AbortIntegration < Command
      describe(:abort_integration, SEQUENCE_STATES, State::Clean,
        Predicate::None, Predicate::Bare,
        Predicate::None, Predicate::Conflicted | Predicate::DirtyIndex,
        Reversibility::Worktree)

      def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
        record = Undo.position(repo)
        return record if record.is_a?(Err)
        undo << record.value

        head = repo.head_oid
        return head if head.is_a?(Err)

        if err = Git.check(LibGit2.repository_state_cleanup(repo.handle))
          return err
        end

        raw = head.value.raw
        annotated = uninitialized LibGit2::AnnotatedCommit
        if err = Git.check(LibGit2.annotated_commit_lookup(pointerof(annotated), repo.handle, pointerof(raw)))
          return err
        end

        opts   = Native.checkout_options(LibGit2::CheckoutStrategy::FORCE.value)
        result = Git.check(LibGit2.reset_from_annotated(repo.handle, annotated, LibGit2::ResetType::HARD, pointerof(opts)))
        LibGit2.annotated_commit_free(annotated)
        return result if result

        if err = repo.reload_index
          return err
        end
        Ok(Value).new(head.value)
      end
    end

    class Rebase < Command
      describe(:rebase, CLEAN_ONLY, State::Clean,
        Predicate::None, Predicate::Bare | Predicate::Conflicted | Predicate::DirtyIndex,
        Predicate::None, Predicate::None,
        Reversibility::Worktree)

      def initialize(@upstream : String, @onto : String?, @branch : String?)
      end

      def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
        record = Undo.position(repo)
        return record if record.is_a?(Err)
        undo << Undo::RebaseAbort.new
        undo << record.value

        signature = repo.signature
        return signature if signature.is_a?(Err)

        handles = [] of LibGit2::AnnotatedCommit

        upstream = Native.annotated(repo, @upstream)
        if upstream.is_a?(Err)
          return upstream
        end
        handles << upstream.value

        onto_handle = Native.null_annotated
        if onto = @onto
          resolved = Native.annotated(repo, onto)
          if resolved.is_a?(Err)
            release(handles)
            return resolved
          end
          onto_handle = resolved.value
          handles << onto_handle
        end

        branch_handle = Native.null_annotated
        if branch = @branch
          resolved = Native.annotated(repo, branch)
          if resolved.is_a?(Err)
            release(handles)
            return resolved
          end
          branch_handle = resolved.value
          handles << branch_handle
        end

        opts = uninitialized LibGit2::RebaseOptions
        if err = Git.check(LibGit2.rebase_options_init(pointerof(opts), 1_u32))
          release(handles)
          return err
        end

        rebase = uninitialized LibGit2::Rebase
        init = Git.check(LibGit2.rebase_init(pointerof(rebase), repo.handle, branch_handle, upstream.value, onto_handle, pointerof(opts)))
        release(handles)
        return init if init

        applied = 0_u64
        loop do
          operation = uninitialized LibGit2::RebaseOperation*
          result = LibGit2.rebase_next(pointerof(operation), rebase)
          break if result == LibGit2::ErrorCode::ITEROVER.value

          if result != 0
            failure = Err.capture(result)
            LibGit2.rebase_free(rebase)
            return failure
          end

          if operation.value.type.exec?
            LibGit2.rebase_free(rebase)
            return Err.invalid("rebase exec operations are not supported")
          end

          created = uninitialized LibGit2::Oid
          committed = LibGit2.rebase_commit(pointerof(created), rebase, nil, signature.value, nil, nil)

          if committed == LibGit2::ErrorCode::EAPPLIED.value
            next
          end

          if committed != 0
            failure = Err.capture(committed)
            LibGit2.rebase_free(rebase)
            return failure
          end

          applied += 1
        end

        finish = Git.check(LibGit2.rebase_finish(rebase, signature.value))
        LibGit2.rebase_free(rebase)
        return finish if finish

        if err = repo.reload_index
          return err
        end
        Ok(Value).new(applied)
      end

      private def release(handles : Array(LibGit2::AnnotatedCommit)) : Nil
        handles.each { |handle| LibGit2.annotated_commit_free(handle) }
      end
    end

    class AbortRebase < Command
      describe(:abort_rebase, REBASE_STATES, State::Clean,
        Predicate::None, Predicate::Bare,
        Predicate::None, Predicate::Conflicted | Predicate::DirtyIndex,
        Reversibility::Worktree)

      def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
        record = Undo.position(repo)
        return record if record.is_a?(Err)
        undo << record.value

        rebase = uninitialized LibGit2::Rebase
        if err = Git.check(LibGit2.rebase_open(pointerof(rebase), repo.handle, nil))
          return err
        end

        result = Git.check(LibGit2.rebase_abort(rebase))
        LibGit2.rebase_free(rebase)
        return result if result

        if err = repo.reload_index
          return err
        end
        Ok(Value).new(true)
      end
    end
  end
end
