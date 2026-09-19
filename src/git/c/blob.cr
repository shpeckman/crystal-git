# src/git/c/blob.cr
@[Link("git2")]
lib LibGit2
  # ============================================================================
  # BLOBS (git2/blob.h)
  # ============================================================================

  enum BlobFilterFlag
    CHECK_FOR_BINARY       = 1
    NO_SYSTEM_ATTRIBUTES   = 2
    ATTRIBUTES_FROM_HEAD   = 4
    ATTRIBUTES_FROM_COMMIT = 8
  end

  struct BlobFilterOptions
    version        : LibC::Int
    flags          : LibC::UInt32
    commit_id      : Oid*
    attr_commit_id : Oid
  end

  fun blob_lookup = git_blob_lookup(blob : Blob*, repo : Repository, id : Oid*) : LibC::Int
  fun blob_lookup_prefix = git_blob_lookup_prefix(blob : Blob*, repo : Repository, id : Oid*, len : LibC::SizeT) : LibC::Int
  fun blob_free = git_blob_free(blob : Blob)
  fun blob_id = git_blob_id(blob : Blob) : Oid*
  fun blob_owner = git_blob_owner(blob : Blob) : Repository
  fun blob_rawcontent = git_blob_rawcontent(blob : Blob) : Void*
  fun blob_rawsize = git_blob_rawsize(blob : Blob) : UInt64

  fun blob_filter_options_init = git_blob_filter_options_init(opts : BlobFilterOptions*, version : LibC::UInt) : LibC::Int
  fun blob_filter = git_blob_filter(out_buf : Buf*, blob : Blob, as_path : LibC::Char*, opts : BlobFilterOptions*) : LibC::Int

  fun blob_create_from_workdir = git_blob_create_from_workdir(id : Oid*, repo : Repository, relative_path : LibC::Char*) : LibC::Int
  fun blob_create_from_disk = git_blob_create_from_disk(id : Oid*, repo : Repository, path : LibC::Char*) : LibC::Int
  fun blob_create_from_stream = git_blob_create_from_stream(out_stream : Writestream*, repo : Repository, hintpath : LibC::Char*) : LibC::Int
  fun blob_create_from_stream_commit = git_blob_create_from_stream_commit(out_oid : Oid*, stream : Writestream) : LibC::Int
  fun blob_create_from_buffer = git_blob_create_from_buffer(id : Oid*, repo : Repository, buffer : Void*, len : LibC::SizeT) : LibC::Int

  fun blob_is_binary = git_blob_is_binary(blob : Blob) : LibC::Int
  fun blob_data_is_binary = git_blob_data_is_binary(data : LibC::Char*, len : LibC::SizeT) : LibC::Int
  fun blob_dup = git_blob_dup(out_blob : Blob*, source : Blob) : LibC::Int
end
