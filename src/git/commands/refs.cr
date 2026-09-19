# src/git/commands/refs.cr
module Git::Commands
  class CreateBranch < Command
    describe(:create_branch, CLEAN_ONLY, nil,
      Predicate::None, Predicate::UnbornHead,
      Predicate::None, Predicate::None,
      Reversibility::RefOnly)

    def initialize(@name : String, @target : String, @flags : BranchFlag)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      prior   = nil.as(Oid?)
      existed = false
      existing = uninitialized LibGit2::Reference
      if LibGit2.branch_lookup(pointerof(existing), repo.handle, @name, LibGit2::BranchType::LOCAL) == 0
        target  = LibGit2.reference_target(existing)
        prior   = Oid.from(target) unless target.null?
        existed = true
        LibGit2.reference_free(existing)
      end
      undo << Undo::Ref.new("refs/heads/#{@name}", prior, existed)

      lookup = Native.commit(repo, @target)
      return lookup if lookup.is_a?(Err)
      commit = lookup.value

      ref = uninitialized LibGit2::Reference
      result = LibGit2.branch_create(pointerof(ref), repo.handle, @name, commit, @flags.force? ? 1 : 0)
      LibGit2.commit_free(commit)

      if err = Git.check(result)
        return err
      end

      target = LibGit2.reference_target(ref)
      oid    = target.null? ? nil : Oid.from(target)
      LibGit2.reference_free(ref)
      Ok(Value).new(oid)
    end
  end

  class DeleteBranch < Command
    describe(:delete_branch, CLEAN_ONLY, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::RefOnly)

    def initialize(@name : String)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      ref = uninitialized LibGit2::Reference
      if err = Git.check(LibGit2.branch_lookup(pointerof(ref), repo.handle, @name, LibGit2::BranchType::LOCAL))
        return err
      end

      if LibGit2.branch_is_head(ref) == 1
        LibGit2.reference_free(ref)
        return Err.invalid("cannot delete the currently checked out branch #{@name}")
      end

      full   = String.new(LibGit2.reference_name(ref))
      target = LibGit2.reference_target(ref)
      oid    = target.null? ? nil : Oid.from(target)
      undo << Undo::Ref.new(full, oid, true)

      result = Git.check(LibGit2.branch_delete(ref))
      LibGit2.reference_free(ref)
      return result if result
      Ok(Value).new(full)
    end
  end

  class MoveBranch < Command
    describe(:move_branch, CLEAN_ONLY, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::RefOnly)

    def initialize(@name : String, @new_name : String, @flags : BranchFlag)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      ref = uninitialized LibGit2::Reference
      if err = Git.check(LibGit2.branch_lookup(pointerof(ref), repo.handle, @name, LibGit2::BranchType::LOCAL))
        return err
      end

      source = String.new(LibGit2.reference_name(ref))
      target = LibGit2.reference_target(ref)
      oid    = target.null? ? nil : Oid.from(target)

      destination = "refs/heads/#{@new_name}"
      prior       = nil.as(Oid?)
      existed     = false
      clash = uninitialized LibGit2::Reference
      if LibGit2.branch_lookup(pointerof(clash), repo.handle, @new_name, LibGit2::BranchType::LOCAL) == 0
        existing = LibGit2.reference_target(clash)
        prior    = Oid.from(existing) unless existing.null?
        existed  = true
        LibGit2.reference_free(clash)
      end

      undo << Undo::Ref.new(destination, prior, existed)
      undo << Undo::Ref.new(source, oid, true)

      moved = uninitialized LibGit2::Reference
      result = Git.check(LibGit2.branch_move(pointerof(moved), ref, @new_name, @flags.force? ? 1 : 0))
      LibGit2.reference_free(ref)
      return result if result

      name = String.new(LibGit2.reference_name(moved))
      LibGit2.reference_free(moved)
      Ok(Value).new(name)
    end
  end

  class SetUpstream < Command
    describe(:set_upstream, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::RefOnly)

    def initialize(@branch : String, @upstream : String?)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      record = Undo::Upstream.capture(repo, @branch)
      return record if record.is_a?(Err)
      undo << record.value

      ref = uninitialized LibGit2::Reference
      if err = Git.check(LibGit2.branch_lookup(pointerof(ref), repo.handle, @branch, LibGit2::BranchType::LOCAL))
        return err
      end

      result = Git.check(LibGit2.branch_set_upstream(ref, Native.pointer(@upstream)))
      LibGit2.reference_free(ref)
      return result if result
      Ok(Value).new(@upstream)
    end
  end

  class Tag < Command
    describe(:tag, StateSet::All, nil,
      Predicate::None, Predicate::UnbornHead,
      Predicate::None, Predicate::None,
      Reversibility::RefOnly)

    def initialize(@name : String, @target : String, @message : String?, @flags : TagFlag)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      full    = "refs/tags/#{@name}"
      prior   = nil.as(Oid?)
      existed = false
      existing = uninitialized LibGit2::Reference
      if LibGit2.reference_lookup(pointerof(existing), repo.handle, full) == 0
        target  = LibGit2.reference_target(existing)
        prior   = Oid.from(target) unless target.null?
        existed = true
        LibGit2.reference_free(existing)
      end
      undo << Undo::Ref.new(full, prior, existed)

      object = uninitialized LibGit2::Object
      if err = Git.check(LibGit2.revparse_single(pointerof(object), repo.handle, @target))
        return err
      end

      created = uninitialized LibGit2::Oid
      force = @flags.force? ? 1 : 0

      result = if message = @message
                 signature = repo.signature
                 if signature.is_a?(Err)
                   Native.free_object(object)
                   return signature
                 end
                 LibGit2.tag_create(pointerof(created), repo.handle, @name, object, signature.value, message, force)
               else
                 LibGit2.tag_create_lightweight(pointerof(created), repo.handle, @name, object, force)
               end

      Native.free_object(object)
      if err = Git.check(result)
        return err
      end
      Ok(Value).new(Oid.new(created))
    end
  end

  class DeleteTag < Command
    describe(:delete_tag, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::RefOnly)

    def initialize(@name : String)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      full = "refs/tags/#{@name}"
      ref = uninitialized LibGit2::Reference
      if err = Git.check(LibGit2.reference_lookup(pointerof(ref), repo.handle, full))
        return err
      end
      target = LibGit2.reference_target(ref)
      oid    = target.null? ? nil : Oid.from(target)
      LibGit2.reference_free(ref)

      undo << Undo::Ref.new(full, oid, true)

      if err = Git.check(LibGit2.tag_delete(repo.handle, @name))
        return err
      end
      Ok(Value).new(full)
    end
  end
end
