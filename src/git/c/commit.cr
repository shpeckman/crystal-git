# src/git/c/commit.cr
@[Link("git2")]
lib LibGit2
  # ============================================================================
  # COMMITS (git2/commit.h & git2/annotated_commit.h)
  # ============================================================================

  type Commitbuilder = Void*

  struct CommitHeader
    field : LibC::Char*
    value : LibC::Char*
  end

  alias CommitSignatureCb = (Commitbuilder, Repository, LibC::Char*, Void* -> LibC::Int)

  struct CommitCreateOptions
    version            : LibC::UInt
    allow_empty_commit : UInt32 # Represents the 1-bit bitfield padded to 32 bits
    author             : Signature*
    committer          : Signature*
    message_encoding   : LibC::Char*
    extra_headers      : CommitHeader*
    extra_headers_len  : LibC::SizeT
    sign               : CommitSignatureCb
    payload            : Void*
  end

  struct CommitCreateExtOptions
    version           : LibC::UInt
    update_ref        : LibC::Char*
    message_encoding  : LibC::Char*
    extra_headers     : CommitHeader*
    extra_headers_len : LibC::SizeT
    sign              : CommitSignatureCb
    payload           : Void*
  end

  alias CommitCreateCb = (Oid*, Signature*, Signature*, LibC::Char*, LibC::Char*, Tree, LibC::SizeT, Commit*, Void* -> LibC::Int)

  # Annotated Commit Functions
  fun annotated_commit_from_ref = git_annotated_commit_from_ref(out_commit : AnnotatedCommit*, repo : Repository, ref : Reference) : LibC::Int
  fun annotated_commit_from_fetchhead = git_annotated_commit_from_fetchhead(out_commit : AnnotatedCommit*, repo : Repository, branch_name : LibC::Char*, remote_url : LibC::Char*, id : Oid*) : LibC::Int
  fun annotated_commit_lookup = git_annotated_commit_lookup(out_commit : AnnotatedCommit*, repo : Repository, id : Oid*) : LibC::Int
  fun annotated_commit_from_revspec = git_annotated_commit_from_revspec(out_commit : AnnotatedCommit*, repo : Repository, revspec : LibC::Char*) : LibC::Int
  fun annotated_commit_id = git_annotated_commit_id(commit : AnnotatedCommit) : Oid*
  fun annotated_commit_ref = git_annotated_commit_ref(commit : AnnotatedCommit) : LibC::Char*
  fun annotated_commit_free = git_annotated_commit_free(commit : AnnotatedCommit)

  # Commit Functions
  fun commit_lookup = git_commit_lookup(commit : Commit*, repo : Repository, id : Oid*) : LibC::Int
  fun commit_lookup_prefix = git_commit_lookup_prefix(commit : Commit*, repo : Repository, id : Oid*, len : LibC::SizeT) : LibC::Int
  fun commit_free = git_commit_free(commit : Commit)
  fun commit_id = git_commit_id(commit : Commit) : Oid*
  fun commit_owner = git_commit_owner(commit : Commit) : Repository
  fun commit_message_encoding = git_commit_message_encoding(commit : Commit) : LibC::Char*
  fun commit_message = git_commit_message(commit : Commit) : LibC::Char*
  fun commit_message_raw = git_commit_message_raw(commit : Commit) : LibC::Char*
  fun commit_summary = git_commit_summary(commit : Commit) : LibC::Char*
  fun commit_body = git_commit_body(commit : Commit) : LibC::Char*
  fun commit_time = git_commit_time(commit : Commit) : Int64
  fun commit_time_offset = git_commit_time_offset(commit : Commit) : LibC::Int
  fun commit_committer = git_commit_committer(commit : Commit) : Signature*
  fun commit_author = git_commit_author(commit : Commit) : Signature*
  fun commit_committer_with_mailmap = git_commit_committer_with_mailmap(out_sig : Signature**, commit : Commit, mailmap : Mailmap) : LibC::Int
  fun commit_author_with_mailmap = git_commit_author_with_mailmap(out_sig : Signature**, commit : Commit, mailmap : Mailmap) : LibC::Int
  fun commit_raw_header = git_commit_raw_header(commit : Commit) : LibC::Char*
  fun commit_tree = git_commit_tree(tree_out : Tree*, commit : Commit) : LibC::Int
  fun commit_tree_id = git_commit_tree_id(commit : Commit) : Oid*
  fun commit_parentcount = git_commit_parentcount(commit : Commit) : LibC::UInt
  fun commit_parent = git_commit_parent(out_commit : Commit*, commit : Commit, n : LibC::UInt) : LibC::Int
  fun commit_parent_id = git_commit_parent_id(commit : Commit, n : LibC::UInt) : Oid*
  fun commit_nth_gen_ancestor = git_commit_nth_gen_ancestor(ancestor : Commit*, commit : Commit, n : LibC::UInt) : LibC::Int
  fun commit_header_field = git_commit_header_field(out_buf : Buf*, commit : Commit, field : LibC::Char*) : LibC::Int
  fun commit_extract_signature = git_commit_extract_signature(signature : Buf*, signed_data : Buf*, repo : Repository, commit_id : Oid*, field : LibC::Char*) : LibC::Int

  fun commitbuilder_add_header = git_commitbuilder_add_header(builder : Commitbuilder, field : LibC::Char*, value : LibC::Char*) : LibC::Int
  fun commit_create_options_init = git_commit_create_options_init(opts : CommitCreateOptions*, version : LibC::UInt) : LibC::Int
  fun commit_create_from_stage = git_commit_create_from_stage(id : Oid*, repo : Repository, message : LibC::Char*, opts : CommitCreateOptions*) : LibC::Int
  fun commit_create_ext_options_init = git_commit_create_ext_options_init(opts : CommitCreateExtOptions*, version : LibC::UInt) : LibC::Int

  fun commit_create_ext = git_commit_create_ext(id_out : Oid*, repo : Repository, author : Signature*, committer : Signature*, message : LibC::Char*, tree : Tree, parent_count : LibC::SizeT, parents : Commit*, opts : CommitCreateExtOptions*) : LibC::Int
  fun commit_create = git_commit_create(id : Oid*, repo : Repository, update_ref : LibC::Char*, author : Signature*, committer : Signature*, message_encoding : LibC::Char*, message : LibC::Char*, tree : Tree, parent_count : LibC::SizeT, parents : Commit*) : LibC::Int
  fun commit_create_v = git_commit_create_v(id : Oid*, repo : Repository, update_ref : LibC::Char*, author : Signature*, committer : Signature*, message_encoding : LibC::Char*, message : LibC::Char*, tree : Tree, parent_count : LibC::SizeT, ...) : LibC::Int
  fun commit_create_from_tree = git_commit_create_from_tree(id : Oid*, repo : Repository, tree : Tree, message : LibC::Char*, opts : CommitCreateOptions*) : LibC::Int
  fun commit_amend_from_stage = git_commit_amend_from_stage(id : Oid*, repo : Repository, message : LibC::Char*, opts : CommitCreateOptions*) : LibC::Int
  fun commit_amend_from_tree = git_commit_amend_from_tree(id : Oid*, repo : Repository, tree : Tree, message : LibC::Char*, opts : CommitCreateOptions*) : LibC::Int
  fun commit_amend = git_commit_amend(id : Oid*, commit_to_amend : Commit, update_ref : LibC::Char*, author : Signature*, committer : Signature*, message_encoding : LibC::Char*, message : LibC::Char*, tree : Tree) : LibC::Int
  fun commit_create_buffer = git_commit_create_buffer(out_buf : Buf*, repo : Repository, author : Signature*, committer : Signature*, message_encoding : LibC::Char*, message : LibC::Char*, tree : Tree, parent_count : LibC::SizeT, parents : Commit*) : LibC::Int
  fun commit_create_with_signature = git_commit_create_with_signature(out_oid : Oid*, repo : Repository, commit_content : LibC::Char*, signature : LibC::Char*, signature_field : LibC::Char*) : LibC::Int
  fun commit_dup = git_commit_dup(out_commit : Commit*, source : Commit) : LibC::Int

  fun commitarray_dispose = git_commitarray_dispose(array : CommitArray*)
end
