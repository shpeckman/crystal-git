# src/git/commands/history.cr
module Git::Commands
  class Commit < Command
    describe(:commit, MUTABLE_STATES, State::Clean,
      Predicate::DirtyIndex, Predicate::Bare | Predicate::Conflicted,
      Predicate::None, Predicate::DirtyIndex,
      Reversibility::RefOnly, CLEAN_ONLY)

    def initialize(@message : String)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      record = Undo.position(repo)
      return record if record.is_a?(Err)
      undo << record.value

      index = repo.index
      return index if index.is_a?(Err)
      index_handle = index.value

      signature = repo.signature
      return signature if signature.is_a?(Err)
      author = signature.value

      tree_oid = uninitialized LibGit2::Oid
      if err = Git.check(LibGit2.index_write_tree(pointerof(tree_oid), index_handle))
        return err
      end

      tree = uninitialized LibGit2::Tree
      if err = Git.check(LibGit2.tree_lookup(pointerof(tree), repo.handle, pointerof(tree_oid)))
        return err
      end

      parents = collect_parents(repo)
      if parents.is_a?(Err)
        LibGit2.tree_free(tree)
        return parents
      end
      handles = parents.value

      created = uninitialized LibGit2::Oid
      result = LibGit2.commit_create(
        pointerof(created), repo.handle, "HEAD",
        author, author, nil, @message,
        tree, handles.size.to_u64, handles.to_unsafe)

      handles.each { |parent| LibGit2.commit_free(parent) }
      LibGit2.tree_free(tree)

      if err = Git.check(result)
        return err
      end
      if err = Git.check(LibGit2.repository_state_cleanup(repo.handle))
        return err
      end
      Ok(Value).new(Oid.new(created))
    end

    private def collect_parents(repo : Repo) : Ok(Array(LibGit2::Commit)) | Err
      handles = [] of LibGit2::Commit

      unless LibGit2.repository_head_unborn(repo.handle) == 1
        head = repo.head_oid
        return head if head.is_a?(Err)
        lookup = lookup_commit(repo, head.value)
        return lookup if lookup.is_a?(Err)
        handles << lookup.value
      end

      oids  = [] of Oid
      boxed = Box.box(oids)
      result = LibGit2.repository_mergehead_foreach(repo.handle, ->(oid : LibGit2::Oid*, payload : Void*) {
        collected = Box(Array(Oid)).unbox(payload)
        collected << Oid.from(oid)
        0
      }, boxed)

      unless result == 0 || result == LibGit2::ErrorCode::ENOTFOUND.value
        handles.each { |parent| LibGit2.commit_free(parent) }
        return Err.capture(result)
      end

      oids.each do |oid|
        lookup = lookup_commit(repo, oid)
        if lookup.is_a?(Err)
          handles.each { |parent| LibGit2.commit_free(parent) }
          return lookup
        end
        handles << lookup.value
      end

      Ok(Array(LibGit2::Commit)).new(handles)
    end

    private def lookup_commit(repo : Repo, oid : Oid) : Ok(LibGit2::Commit) | Err
      raw = oid.raw
      commit = uninitialized LibGit2::Commit
      if err = Git.check(LibGit2.commit_lookup(pointerof(commit), repo.handle, pointerof(raw)))
        return err
      end
      Ok(LibGit2::Commit).new(commit)
    end
  end

  class SetHead < Command
    describe(:set_head, CLEAN_ONLY, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::RefOnly)

    def initialize(@refname : String)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      record = Undo.attachment(repo)
      return record if record.is_a?(Err)
      undo << record.value

      if err = Git.check(LibGit2.repository_set_head(repo.handle, @refname))
        return err
      end
      if err = repo.reload_index
        return err
      end
      Ok(Value).new(@refname)
    end
  end

  class Checkout < Command
    describe(:checkout, CLEAN_ONLY, nil,
      Predicate::None, Predicate::Bare | Predicate::Conflicted,
      Predicate::None, Predicate::DirtyIndex,
      Reversibility::Worktree)

    def initialize(@target : String, @flags : CheckoutFlag)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      record = Undo.attachment(repo)
      return record if record.is_a?(Err)
      undo << record.value

      refname = nil.as(String?)
      annotated = uninitialized LibGit2::AnnotatedCommit

      ref = uninitialized LibGit2::Reference
      if LibGit2.reference_dwim(pointerof(ref), repo.handle, @target) == 0
        refname = String.new(LibGit2.reference_name(ref))
        result  = Git.check(LibGit2.annotated_commit_from_ref(pointerof(annotated), repo.handle, ref))
        LibGit2.reference_free(ref)
        return result if result
      else
        resolved = Native.annotated(repo, @target)
        return resolved if resolved.is_a?(Err)
        annotated = resolved.value
      end

      commit = uninitialized LibGit2::Commit
      if err = Git.check(LibGit2.commit_lookup(pointerof(commit), repo.handle, LibGit2.annotated_commit_id(annotated)))
        LibGit2.annotated_commit_free(annotated)
        return err
      end

      opts   = Native.checkout_options(@flags.value)
      result = Git.check(LibGit2.checkout_tree(repo.handle, commit.as(LibGit2::Object), pointerof(opts)))
      LibGit2.commit_free(commit)

      if result
        LibGit2.annotated_commit_free(annotated)
        return result
      end

      attach = if name = refname
                 Git.check(LibGit2.repository_set_head(repo.handle, name))
               else
                 Git.check(LibGit2.repository_set_head_detached_from_annotated(repo.handle, annotated))
               end
      LibGit2.annotated_commit_free(annotated)
      return attach if attach

      if err = repo.reload_index
        return err
      end
      Ok(Value).new(refname || @target)
    end
  end

  class Reset < Command
    describe(:reset, MUTABLE_STATES, State::Clean,
      Predicate::None, Predicate::Bare | Predicate::UnbornHead,
      Predicate::None, Predicate::DirtyIndex,
      Reversibility::Worktree)

    def initialize(@target : String, @mode : ResetMode)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      record = Undo.position(repo)
      return record if record.is_a?(Err)
      undo << record.value

      resolved = Native.annotated(repo, @target)
      return resolved if resolved.is_a?(Err)
      annotated = resolved.value

      oid    = Oid.from(LibGit2.annotated_commit_id(annotated))
      opts   = Native.checkout_options(LibGit2::CheckoutStrategy::FORCE.value)
      result = Git.check(LibGit2.reset_from_annotated(repo.handle, annotated, @mode.to_native, pointerof(opts)))
      LibGit2.annotated_commit_free(annotated)
      return result if result

      if err = repo.reload_index
        return err
      end
      Ok(Value).new(oid)
    end
  end
end
