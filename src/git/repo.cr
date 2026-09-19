# src/git/repo.cr
class Git::Repo
  getter handle        : LibGit2::Repository
  property credentials : Credentials?

  @index     : LibGit2::Index
  @signature : LibGit2::Signature*
  @closed    : Bool

  def self.open(path : String) : Ok(Repo) | Err
    if err = Library.acquire
      return err
    end
    handle = uninitialized LibGit2::Repository
    if err = Git.check(LibGit2.repository_open_ext(pointerof(handle), path, 0_u32, nil))
      Library.release
      return err
    end
    Ok(Repo).new(new(handle))
  end

  def self.open(path : String, &)
    result = open(path)
    return result if result.is_a?(Err)
    repo = result.value
    begin
      yield repo
    ensure
      repo.close
    end
  end

  def self.init(path : String, bare : Bool = false) : Ok(Repo) | Err
    if err = Library.acquire
      return err
    end
    handle = uninitialized LibGit2::Repository
    if err = Git.check(LibGit2.repository_init(pointerof(handle), path, bare ? 1_u32 : 0_u32))
      Library.release
      return err
    end
    Ok(Repo).new(new(handle))
  end

  def initialize(@handle : LibGit2::Repository)
    @index       = Pointer(Void).null.as(LibGit2::Index)
    @signature   = Pointer(LibGit2::Signature).null
    @closed      = false
    @credentials = nil
  end

  def index : Ok(LibGit2::Index) | Err
    return Ok(LibGit2::Index).new(@index) unless @index.null?
    handle = uninitialized LibGit2::Index
    if err = Git.check(LibGit2.repository_index(pointerof(handle), @handle))
      return err
    end
    @index = handle
    Ok(LibGit2::Index).new(handle)
  end

  def reload_index : Err?
    return nil if @index.null?
    Git.check(LibGit2.index_read(@index, 1))
  end

  def signature : Ok(LibGit2::Signature*) | Err
    return Ok(LibGit2::Signature*).new(@signature) unless @signature.null?
    out_sig = uninitialized LibGit2::Signature*
    if err = Git.check(LibGit2.signature_default(pointerof(out_sig), @handle))
      return err
    end
    @signature = out_sig
    Ok(LibGit2::Signature*).new(out_sig)
  end

  def head_oid : Ok(Oid) | Err
    ref = uninitialized LibGit2::Reference
    if err = Git.check(LibGit2.repository_head(pointerof(ref), @handle))
      return err
    end
    target = LibGit2.reference_target(ref)
    if target.null?
      LibGit2.reference_free(ref)
      return Err.invalid("HEAD does not resolve to a direct target")
    end
    oid = Oid.from(target)
    LibGit2.reference_free(ref)
    Ok(Oid).new(oid)
  end

  def head_symbolic_name : Ok(String) | Err
    ref = uninitialized LibGit2::Reference
    if err = Git.check(LibGit2.reference_lookup(pointerof(ref), @handle, "HEAD"))
      return err
    end
    symbolic = LibGit2.reference_symbolic_target(ref)
    name     = symbolic.null? ? "HEAD" : String.new(symbolic)
    LibGit2.reference_free(ref)
    Ok(String).new(name)
  end

  def conditions : Ok(Conditions) | Err
    predicates = Predicate::None
    predicates |= Predicate::Bare if LibGit2.repository_is_bare(@handle) == 1
    predicates |= Predicate::UnbornHead if LibGit2.repository_head_unborn(@handle) == 1
    predicates |= Predicate::DetachedHead if LibGit2.repository_head_detached(@handle) == 1

    unless predicates.bare?
      result = index
      return result if result.is_a?(Err)
      handle = result.value
      predicates |= Predicate::Conflicted if LibGit2.index_has_conflicts(handle) == 1
      predicates |= Predicate::DirtyIndex if dirty?(handle)
    end

    state = State.from_native(LibGit2.repository_state(@handle))
    Ok(Conditions).new(Conditions.new(state, predicates))
  end

  def close : Nil
    return if @closed
    @closed = true
    LibGit2.signature_free(@signature) unless @signature.null?
    LibGit2.index_free(@index) unless @index.null?
    LibGit2.repository_free(@handle)
    @signature = Pointer(LibGit2::Signature).null
    @index     = Pointer(Void).null.as(LibGit2::Index)
    Library.release
  end

  def closed? : Bool
    @closed
  end

  private def dirty?(index_handle : LibGit2::Index) : Bool
    if LibGit2.repository_head_unborn(@handle) == 1
      return LibGit2.index_entrycount(index_handle) > 0
    end

    ref = uninitialized LibGit2::Reference
    return false unless LibGit2.repository_head(pointerof(ref), @handle) == 0

    object = uninitialized LibGit2::Object
    peeled = LibGit2.reference_peel(pointerof(object), ref, LibGit2::ObjectType::TREE)
    LibGit2.reference_free(ref)
    return false unless peeled == 0

    opts = uninitialized LibGit2::DiffOptions
    LibGit2.diff_options_init(pointerof(opts), 1_u32)
    diff = uninitialized LibGit2::Diff
    result = LibGit2.diff_tree_to_index(pointerof(diff), @handle, object.as(LibGit2::Tree), index_handle, pointerof(opts))
    Native.free_object(object)
    return false unless result == 0

    deltas = LibGit2.diff_num_deltas(diff)
    LibGit2.diff_free(diff)
    deltas > 0
  end
end
