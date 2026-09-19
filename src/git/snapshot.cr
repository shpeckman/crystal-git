# src/git/snapshot.cr
module Git
  class Snapshot
    SAVE_MESSAGE = "crystal-git stream snapshot"

    def self.capture(repo : Repo) : Ok(Snapshot) | Err
      attachment = Undo.attachment(repo)
      return attachment if attachment.is_a?(Err)

      head = repo.head_oid
      return head if head.is_a?(Err)

      signature = repo.signature
      return signature if signature.is_a?(Err)

      opts = uninitialized LibGit2::StashSaveOptions
      if err = Git.check(LibGit2.stash_save_options_init(pointerof(opts), 1_u32))
        return err
      end
      opts.flags = LibGit2::StashFlags::INCLUDE_UNTRACKED.value
      opts.stasher = signature.value
      opts.message = SAVE_MESSAGE.to_unsafe

      oid = uninitialized LibGit2::Oid
      result = LibGit2.stash_save_with_opts(pointerof(oid), repo.handle, pointerof(opts))

      stashed = nil.as(Oid?)
      if result == 0
        stashed = Oid.new(oid)
      elsif result != LibGit2::ErrorCode::ENOTFOUND.value
        return Err.capture(result)
      end

      if stashed
        position = Stash.locate(repo, stashed)
        return Err.invalid("snapshot stash could not be located") unless position
        if err = reinstate(repo, position)
          return err
        end
      end

      Ok(Snapshot).new(new(attachment.value, head.value, stashed))
    end

    def self.reinstate(repo : Repo, position : Int32) : Err?
      opts = uninitialized LibGit2::StashApplyOptions
      if err = Git.check(LibGit2.stash_apply_options_init(pointerof(opts), 1_u32))
        return err
      end
      opts.flags = LibGit2::StashApplyFlags::REINSTATE_INDEX.value
      opts.checkout_options = Native.checkout_options(LibGit2::CheckoutStrategy::FORCE.value)

      failure = Git.check(LibGit2.stash_apply(repo.handle, position.to_u64, pointerof(opts)))
      return failure if failure
      repo.reload_index
    end

    def initialize(@attachment : Undo, @head : Oid, @stashed : Oid?)
    end

    def restore(repo : Repo) : Err?
      if err = Git.check(LibGit2.repository_state_cleanup(repo.handle))
        return err
      end

      raw = @head.raw
      annotated = uninitialized LibGit2::AnnotatedCommit
      if err = Git.check(LibGit2.annotated_commit_lookup(pointerof(annotated), repo.handle, pointerof(raw)))
        return err
      end
      opts    = Native.checkout_options(LibGit2::CheckoutStrategy::FORCE.value)
      failure = Git.check(LibGit2.reset_from_annotated(repo.handle, annotated, LibGit2::ResetType::HARD, pointerof(opts)))
      LibGit2.annotated_commit_free(annotated)
      return failure if failure

      if err = repo.reload_index
        return err
      end
      if err = @attachment.apply(repo)
        return err
      end

      stashed = @stashed
      return nil unless stashed

      position = Stash.locate(repo, stashed)
      return Err.invalid("snapshot stash is no longer present") unless position

      if err = Snapshot.reinstate(repo, position)
        return err
      end
      @stashed = nil
      Git.check(LibGit2.stash_drop(repo.handle, position.to_u64))
    end

    def discard(repo : Repo) : Err?
      stashed = @stashed
      return nil unless stashed
      @stashed = nil
      position = Stash.locate(repo, stashed)
      return nil unless position
      Git.check(LibGit2.stash_drop(repo.handle, position.to_u64))
    end
  end
end
