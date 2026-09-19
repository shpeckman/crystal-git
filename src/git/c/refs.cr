# src/git/c/refs.cr
@[Link("git2")]
lib LibGit2
  # ============================================================================
  # REFERENCES (git2/refs.h)
  # ============================================================================

  enum ReferenceFormatType
    NORMAL            = 0
    ALLOW_ONELEVEL    = 1
    REFSPEC_PATTERN   = 2
    REFSPEC_SHORTHAND = 4
  end

  alias ReferenceForeachCb = (Reference, Void* -> LibC::Int)
  alias ReferenceForeachNameCb = (LibC::Char*, Void* -> LibC::Int)

  fun reference_lookup = git_reference_lookup(out_ref : Reference*, repo : Repository, name : LibC::Char*) : LibC::Int
  fun reference_name_to_id = git_reference_name_to_id(out_oid : Oid*, repo : Repository, name : LibC::Char*) : LibC::Int
  fun reference_dwim = git_reference_dwim(out_ref : Reference*, repo : Repository, shorthand : LibC::Char*) : LibC::Int

  fun reference_symbolic_create_matching = git_reference_symbolic_create_matching(out_ref : Reference*, repo : Repository, name : LibC::Char*, target : LibC::Char*, force : LibC::Int, current_value : LibC::Char*, log_message : LibC::Char*) : LibC::Int
  fun reference_symbolic_create = git_reference_symbolic_create(out_ref : Reference*, repo : Repository, name : LibC::Char*, target : LibC::Char*, force : LibC::Int, log_message : LibC::Char*) : LibC::Int

  fun reference_create = git_reference_create(out_ref : Reference*, repo : Repository, name : LibC::Char*, id : Oid*, force : LibC::Int, log_message : LibC::Char*) : LibC::Int
  fun reference_create_matching = git_reference_create_matching(out_ref : Reference*, repo : Repository, name : LibC::Char*, id : Oid*, force : LibC::Int, current_id : Oid*, log_message : LibC::Char*) : LibC::Int

  fun reference_target = git_reference_target(ref : Reference) : Oid*
  fun reference_target_peel = git_reference_target_peel(ref : Reference) : Oid*
  fun reference_symbolic_target = git_reference_symbolic_target(ref : Reference) : LibC::Char*

  fun reference_type = git_reference_type(ref : Reference) : ReferenceType
  fun reference_name = git_reference_name(ref : Reference) : LibC::Char*
  fun reference_resolve = git_reference_resolve(out_ref : Reference*, ref : Reference) : LibC::Int
  fun reference_owner = git_reference_owner(ref : Reference) : Repository

  fun reference_symbolic_set_target = git_reference_symbolic_set_target(out_ref : Reference*, ref : Reference, target : LibC::Char*, log_message : LibC::Char*) : LibC::Int
  fun reference_set_target = git_reference_set_target(out_ref : Reference*, ref : Reference, id : Oid*, log_message : LibC::Char*) : LibC::Int
  fun reference_rename = git_reference_rename(new_ref : Reference*, ref : Reference, new_name : LibC::Char*, force : LibC::Int, log_message : LibC::Char*) : LibC::Int

  fun reference_delete = git_reference_delete(ref : Reference) : LibC::Int
  fun reference_remove = git_reference_remove(repo : Repository, name : LibC::Char*) : LibC::Int
  fun reference_list = git_reference_list(array : Strarray*, repo : Repository) : LibC::Int

  fun reference_foreach = git_reference_foreach(repo : Repository, callback : ReferenceForeachCb, payload : Void*) : LibC::Int
  fun reference_foreach_name = git_reference_foreach_name(repo : Repository, callback : ReferenceForeachNameCb, payload : Void*) : LibC::Int

  fun reference_dup = git_reference_dup(dest : Reference*, source : Reference) : LibC::Int
  fun reference_free = git_reference_free(ref : Reference)
  fun reference_cmp = git_reference_cmp(ref1 : Reference, ref2 : Reference) : LibC::Int

  fun reference_iterator_new = git_reference_iterator_new(out_iter : ReferenceIterator*, repo : Repository) : LibC::Int
  fun reference_iterator_glob_new = git_reference_iterator_glob_new(out_iter : ReferenceIterator*, repo : Repository, glob : LibC::Char*) : LibC::Int
  fun reference_next = git_reference_next(out_ref : Reference*, iter : ReferenceIterator) : LibC::Int
  fun reference_next_name = git_reference_next_name(out_name : LibC::Char**, iter : ReferenceIterator) : LibC::Int
  fun reference_iterator_free = git_reference_iterator_free(iter : ReferenceIterator)

  fun reference_foreach_glob = git_reference_foreach_glob(repo : Repository, glob : LibC::Char*, callback : ReferenceForeachNameCb, payload : Void*) : LibC::Int

  fun reference_has_log = git_reference_has_log(repo : Repository, refname : LibC::Char*) : LibC::Int
  fun reference_ensure_log = git_reference_ensure_log(repo : Repository, refname : LibC::Char*) : LibC::Int

  fun reference_is_branch = git_reference_is_branch(ref : Reference) : LibC::Int
  fun reference_is_remote = git_reference_is_remote(ref : Reference) : LibC::Int
  fun reference_is_tag = git_reference_is_tag(ref : Reference) : LibC::Int
  fun reference_is_note = git_reference_is_note(ref : Reference) : LibC::Int

  fun reference_normalize_name = git_reference_normalize_name(buffer_out : LibC::Char*, buffer_size : LibC::SizeT, name : LibC::Char*, flags : LibC::UInt) : LibC::Int
  fun reference_peel = git_reference_peel(out_obj : Object*, ref : Reference, type : ObjectType) : LibC::Int
  fun reference_name_is_valid = git_reference_name_is_valid(valid : LibC::Int*, refname : LibC::Char*) : LibC::Int
  fun reference_shorthand = git_reference_shorthand(ref : Reference) : LibC::Char*
end
