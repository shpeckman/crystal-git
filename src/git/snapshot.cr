# src/git/snapshot.cr
module Git
  abstract class Snapshot
    abstract def restore(repo : Repo) : Err?
    abstract def discard(repo : Repo) : Err?

    def self.capture(repo : Repo) : Ok(Snapshot) | Err
      conditions = repo.conditions
      return conditions if conditions.is_a?(Err)

      if conditions.value.predicates.conflicted? || !conditions.value.state.clean?
        Manual.capture(repo)
      else
        Stashed.capture(repo)
      end
    end
  end

  class Snapshot::Stashed < Snapshot
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

      if err = Snapshot::Stashed.reinstate(repo, position)
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

  class Snapshot::Manual < Snapshot
    STATE_ENTRIES = %w[
      MERGE_HEAD MERGE_MSG MERGE_MODE ORIG_HEAD
      CHERRY_PICK_HEAD REVERT_HEAD BISECT_LOG
      rebase-merge rebase-apply sequencer
    ]

    def self.capture(repo : Repo) : Ok(Snapshot) | Err
      attachment = Undo.attachment(repo)
      return attachment if attachment.is_a?(Err)

      head = repo.head_oid
      return head if head.is_a?(Err)

      index = repo.index
      return index if index.is_a?(Err)

      if err = Git.check(LibGit2.index_write(index.value))
        return err
      end

      index_path = Native.text(LibGit2.index_path(index.value))
      return Err.invalid("repository index has no on-disk path") unless index_path
      return Err.invalid("repository index file is missing") unless File.file?(index_path)
      index_bytes = Native.read_bytes(index_path)

      paths = Worktree.candidates(repo)
      return paths if paths.is_a?(Err)

      captured = Worktree.capture(repo, paths.value)
      return captured if captured.is_a?(Err)

      state = capture_state(repo)
      return state if state.is_a?(Err)

      Ok(Snapshot).new(new(attachment.value, head.value, index_bytes, captured.value, state.value))
    end

    def self.capture_state(repo : Repo) : Ok(Hash(String, Bytes)) | Err
      gitdir = Native.gitdir(repo)
      return gitdir if gitdir.is_a?(Err)
      root = gitdir.value

      files = {} of String => Bytes
      STATE_ENTRIES.each do |name|
        full = File.join(root, name)
        if File.directory?(full)
          collect(full, name, files)
        elsif File.file?(full)
          files[name] = Native.read_bytes(full)
        end
      end

      Ok(Hash(String, Bytes)).new(files)
    end

    private def self.collect(directory : String, prefix : String, files : Hash(String, Bytes)) : Nil
      Dir.each_child(directory) do |child|
        full = File.join(directory, child)
        key  = File.join(prefix, child)
        if File.directory?(full)
          collect(full, key, files)
        elsif File.file?(full)
          files[key] = Native.read_bytes(full)
        end
      end
    end

    def initialize(@attachment : Undo, @head : Oid, @index : Bytes,
                   @entries : Array(WorktreeEntry), @state : Hash(String, Bytes))
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
      if err = Worktree.restore(repo, @entries)
        return err
      end
      if err = restore_state(repo)
        return err
      end
      if err = restore_index(repo)
        return err
      end
      if err = @attachment.apply(repo)
        return err
      end

      repo.reload_index
    end

    def discard(repo : Repo) : Err?
      nil
    end

    private def restore_index(repo : Repo) : Err?
      index = repo.index
      return index if index.is_a?(Err)

      path = Native.text(LibGit2.index_path(index.value))
      return Err.invalid("repository index has no on-disk path") unless path

      Native.write_bytes(path, @index)
      nil
    end

    private def restore_state(repo : Repo) : Err?
      gitdir = Native.gitdir(repo)
      return gitdir if gitdir.is_a?(Err)
      root = gitdir.value

      STATE_ENTRIES.each { |name| Native.discard(File.join(root, name)) }
      @state.each { |key, bytes| Native.write_bytes(File.join(root, key), bytes) }
      nil
    end
  end
end
