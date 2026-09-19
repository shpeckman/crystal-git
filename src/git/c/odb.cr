# src/git/c/odb.cr
@[Link("git2")]
lib LibGit2
  # ============================================================================
  # ODB & ODB BACKEND (git2/odb.h, git2/odb_backend.h)
  # ============================================================================

  enum OdbLookupFlags
    NO_REFRESH = 1
  end

  struct OdbOptions
    version  : LibC::UInt
    oid_type : OidType
  end

  struct OdbExpandId
    id     : Oid
    length : LibC::UShort
    type   : ObjectType
  end

  alias OdbForeachCb = (Oid*, Void* -> LibC::Int)

  fun odb_options_init = git_odb_options_init(opts : OdbOptions*, version : LibC::UInt) : LibC::Int
  fun odb_new = git_odb_new(out_odb : Odb*) : LibC::Int
  fun odb_new_ext = git_odb_new_ext(out_odb : Odb*, opts : OdbOptions*) : LibC::Int
  fun odb_open = git_odb_open(out_odb : Odb*, objects_dir : LibC::Char*) : LibC::Int
  fun odb_open_ext = git_odb_open_ext(out_odb : Odb*, objects_dir : LibC::Char*, opts : OdbOptions*) : LibC::Int
  fun odb_add_disk_alternate = git_odb_add_disk_alternate(odb : Odb, path : LibC::Char*) : LibC::Int
  fun odb_free = git_odb_free(db : Odb)

  fun odb_read = git_odb_read(out_obj : OdbObject*, db : Odb, id : Oid*) : LibC::Int
  fun odb_read_prefix = git_odb_read_prefix(out_obj : OdbObject*, db : Odb, short_id : Oid*, len : LibC::SizeT) : LibC::Int
  fun odb_read_header = git_odb_read_header(len_out : LibC::SizeT*, type_out : ObjectType*, db : Odb, id : Oid*) : LibC::Int
  fun odb_exists = git_odb_exists(db : Odb, id : Oid*) : LibC::Int
  fun odb_exists_ext = git_odb_exists_ext(db : Odb, id : Oid*, flags : LibC::UInt) : LibC::Int
  fun odb_exists_prefix = git_odb_exists_prefix(out_oid : Oid*, db : Odb, short_id : Oid*, len : LibC::SizeT) : LibC::Int
  fun odb_expand_ids = git_odb_expand_ids(db : Odb, ids : OdbExpandId*, count : LibC::SizeT) : LibC::Int
  fun odb_refresh = git_odb_refresh(db : Odb) : LibC::Int
  fun odb_foreach = git_odb_foreach(db : Odb, cb : OdbForeachCb, payload : Void*) : LibC::Int

  fun odb_write = git_odb_write(out_oid : Oid*, odb : Odb, data : Void*, len : LibC::SizeT, type : ObjectType) : LibC::Int
  fun odb_open_wstream = git_odb_open_wstream(out_stream : OdbStream*, db : Odb, size : ObjectSizeT, type : ObjectType) : LibC::Int
  fun odb_stream_write = git_odb_stream_write(stream : OdbStream, buffer : LibC::Char*, len : LibC::SizeT) : LibC::Int
  fun odb_stream_finalize_write = git_odb_stream_finalize_write(out_oid : Oid*, stream : OdbStream) : LibC::Int
  fun odb_stream_read = git_odb_stream_read(stream : OdbStream, buffer : LibC::Char*, len : LibC::SizeT) : LibC::Int
  fun odb_stream_free = git_odb_stream_free(stream : OdbStream)
  fun odb_open_rstream = git_odb_open_rstream(out_stream : OdbStream*, len : LibC::SizeT*, type : ObjectType*, db : Odb, oid : Oid*) : LibC::Int
  fun odb_write_pack = git_odb_write_pack(out_pack : OdbWritepack*, db : Odb, progress_cb : Void*, progress_payload : Void*) : LibC::Int
  fun odb_write_multi_pack_index = git_odb_write_multi_pack_index(db : Odb) : LibC::Int

  fun odb_object_dup = git_odb_object_dup(dest : OdbObject*, source : OdbObject) : LibC::Int
  fun odb_object_free = git_odb_object_free(object : OdbObject)
  fun odb_object_id = git_odb_object_id(object : OdbObject) : Oid*
  fun odb_object_data = git_odb_object_data(object : OdbObject) : Void*
  fun odb_object_size = git_odb_object_size(object : OdbObject) : LibC::SizeT
  fun odb_object_type = git_odb_object_type(object : OdbObject) : ObjectType

  fun odb_add_backend = git_odb_add_backend(odb : Odb, backend : OdbBackend, priority : LibC::Int) : LibC::Int
  fun odb_add_alternate = git_odb_add_alternate(odb : Odb, backend : OdbBackend, priority : LibC::Int) : LibC::Int
  fun odb_num_backends = git_odb_num_backends(odb : Odb) : LibC::SizeT
  fun odb_get_backend = git_odb_get_backend(out_backend : OdbBackend*, odb : Odb, pos : LibC::SizeT) : LibC::Int
end
