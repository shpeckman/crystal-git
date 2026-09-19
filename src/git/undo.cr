# src/git/undo.cr
module Git
  abstract class Undo
    abstract def apply(repo : Repo) : Err?

    def self.position(repo : Repo) : Ok(Undo) | Err
      handle = repo.handle

      if LibGit2.repository_head_unborn(handle) == 1
        name = repo.head_symbolic_name
        return name if name.is_a?(Err)
        return Ok(Undo).new(Ref.new(name.value, nil, false))
      end

      if LibGit2.repository_head_detached(handle) == 1
        oid = repo.head_oid
        return oid if oid.is_a?(Err)
        return Ok(Undo).new(Head.new(nil, oid.value))
      end

      ref = uninitialized LibGit2::Reference
      if err = Git.check(LibGit2.repository_head(pointerof(ref), handle))
        return err
      end
      name   = String.new(LibGit2.reference_name(ref))
      target = LibGit2.reference_target(ref)
      oid    = target.null? ? nil : Oid.from(target)
      LibGit2.reference_free(ref)
      Ok(Undo).new(Ref.new(name, oid, true))
    end

    def self.attachment(repo : Repo) : Ok(Undo) | Err
      ref = uninitialized LibGit2::Reference
      if err = Git.check(LibGit2.reference_lookup(pointerof(ref), repo.handle, "HEAD"))
        return err
      end
      symbolic = LibGit2.reference_symbolic_target(ref)
      if symbolic.null?
        target = LibGit2.reference_target(ref)
        oid    = target.null? ? nil : Oid.from(target)
        LibGit2.reference_free(ref)
        return Ok(Undo).new(Head.new(nil, oid))
      end
      name = String.new(symbolic)
      LibGit2.reference_free(ref)
      Ok(Undo).new(Head.new(name, nil))
    end
  end

  class Undo::Ref < Undo
    def initialize(@name : String, @target : Oid?, @existed : Bool)
    end

    def apply(repo : Repo) : Err?
      target = @target
      unless @existed && target
        result = LibGit2.reference_remove(repo.handle, @name)
        return nil if result == LibGit2::ErrorCode::ENOTFOUND.value
        return Git.check(result)
      end
      raw = target.raw
      ref = uninitialized LibGit2::Reference
      if err = Git.check(LibGit2.reference_create(pointerof(ref), repo.handle, @name, pointerof(raw), 1, nil))
        return err
      end
      LibGit2.reference_free(ref)
      nil
    end
  end

  class Undo::Head < Undo
    def initialize(@symbolic : String?, @detached : Oid?)
    end

    def apply(repo : Repo) : Err?
      if symbolic = @symbolic
        return Git.check(LibGit2.repository_set_head(repo.handle, symbolic))
      end
      if detached = @detached
        raw = detached.raw
        return Git.check(LibGit2.repository_set_head_detached(repo.handle, pointerof(raw)))
      end
      nil
    end
  end

  class Undo::IndexTree < Undo
    def self.capture(repo : Repo) : Ok(Undo) | Err
      index = repo.index
      return index if index.is_a?(Err)
      oid = uninitialized LibGit2::Oid
      if err = Git.check(LibGit2.index_write_tree_to(pointerof(oid), index.value, repo.handle))
        return err
      end
      Ok(Undo).new(new(Oid.new(oid)))
    end

    def initialize(@tree : Oid)
    end

    def apply(repo : Repo) : Err?
      index = repo.index
      return index if index.is_a?(Err)
      handle = index.value

      raw = @tree.raw
      tree = uninitialized LibGit2::Tree
      if err = Git.check(LibGit2.tree_lookup(pointerof(tree), repo.handle, pointerof(raw)))
        return err
      end
      failure = Git.check(LibGit2.index_read_tree(handle, tree))
      LibGit2.tree_free(tree)
      return failure if failure
      Git.check(LibGit2.index_write(handle))
    end
  end

  class Undo::StateCleanup < Undo
    def apply(repo : Repo) : Err?
      Git.check(LibGit2.repository_state_cleanup(repo.handle))
    end
  end

  class Undo::RebaseAbort < Undo
    def apply(repo : Repo) : Err?
      rebase = uninitialized LibGit2::Rebase
      return nil unless LibGit2.rebase_open(pointerof(rebase), repo.handle, nil) == 0
      result = Git.check(LibGit2.rebase_abort(rebase))
      LibGit2.rebase_free(rebase)
      result
    end
  end

  class Undo::StashDrop < Undo
    def initialize(@oid : Oid)
    end

    def apply(repo : Repo) : Err?
      position = Stash.locate(repo, @oid)
      return nil unless position
      Git.check(LibGit2.stash_drop(repo.handle, position.to_u64))
    end
  end

  class Undo::Upstream < Undo
    def self.capture(repo : Repo, branch : String) : Ok(Undo) | Err
      ref = uninitialized LibGit2::Reference
      if err = Git.check(LibGit2.branch_lookup(pointerof(ref), repo.handle, branch, LibGit2::BranchType::LOCAL))
        return err
      end

      upstream = uninitialized LibGit2::Reference
      current = nil.as(String?)
      if LibGit2.branch_upstream(pointerof(upstream), ref) == 0
        current = Native.text(LibGit2.reference_shorthand(upstream))
        LibGit2.reference_free(upstream)
      end
      LibGit2.reference_free(ref)

      Ok(Undo).new(new(branch, current))
    end

    def initialize(@branch : String, @upstream : String?)
    end

    def apply(repo : Repo) : Err?
      ref = uninitialized LibGit2::Reference
      if err = Git.check(LibGit2.branch_lookup(pointerof(ref), repo.handle, @branch, LibGit2::BranchType::LOCAL))
        return err
      end
      result = Git.check(LibGit2.branch_set_upstream(ref, Native.pointer(@upstream)))
      LibGit2.reference_free(ref)
      result
    end
  end
end
