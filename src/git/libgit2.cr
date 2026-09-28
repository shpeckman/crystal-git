# src/git/libgit2.cr
@[Link("git2")]
lib LibGit2
  type AnnotatedCommit = Void*
  type Blame = Void*
  type Blob = Void*
  type Commit = Void*
  type CommitGraph = Void*
  type CommitGraphWriter = Void*
  type Config = Void*
  type ConfigBackend = Void*
  type Cert = Void*
  type Credential = Void*
  type Diff = Void*
  type Index = Void*
  type IndexConflictIterator = Void*
  type IndexIterator = Void*
  type Mailmap = Void*
  type MidxWriter = Void*
  type Note = Void*
  type Object = Void*
  type Odb = Void*
  type OdbBackend = Void*
  type OdbObject = Void*
  type OdbStream = Void*
  type OdbWritepack = Void*
  type Packbuilder = Void*
  type Patch = Void*
  type Pathspec = Void*
  type Push = Void*
  type Rebase = Void*
  type Refdb = Void*
  type RefdbBackend = Void*
  type Reference = Void*
  type ReferenceIterator = Void*
  type Reflog = Void*
  type ReflogEntry = Void*
  type Refspec = Void*
  type Remote = Void*
  type RemoteHead = Void*
  type Repository = Void*
  type Revwalk = Void*
  type StatusList = Void*
  type Submodule = Void*
  type Tag = Void*
  type Transaction = Void*
  type Transport = Void*
  type Tree = Void*
  type Treebuilder = Void*
  type TreeEntry = Void*
  type Worktree = Void*
  type Writestream = Void*

  alias ObjectSizeT = UInt64

  struct Time
    time   : Int64
    offset : LibC::Int
    sign   : LibC::Char
  end

  struct Signature
    name  : LibC::Char*
    email : LibC::Char*
    when  : Time
  end

  struct CommitArray
    commits : Commit*
    count   : LibC::SizeT
  end

  enum ObjectType
    ANY     = -2
    INVALID = -1
    COMMIT  =  1
    TREE    =  2
    BLOB    =  3
    TAG     =  4
  end

  enum ReferenceType
    INVALID  = 0
    DIRECT   = 1
    SYMBOLIC = 2
    ALL      = 3
  end

  enum BranchType
    LOCAL  = 1
    REMOTE = 2
    ALL    = 3
  end

  enum FilemodeType
    UNREADABLE      =     0
    TREE            = 16384
    BLOB            = 33188
    BLOB_EXECUTABLE = 33261
    LINK            = 40960
    COMMIT          = 57344
  end

  enum SubmoduleUpdateType
    CHECKOUT = 1
    REBASE   = 2
    MERGE    = 3
    NONE     = 4
    DEFAULT  = 0
  end

  enum SubmoduleIgnoreType
    UNSPECIFIED = -1
    NONE        =  1
    UNTRACKED   =  2
    DIRTY       =  3
    ALL         =  4
  end

  enum SubmoduleRecurseType
    NO       = 0
    YES      = 1
    ONDEMAND = 2
  end

  enum RefdbType
    FILES    = 1
    REFTABLE = 2
  end

  enum ErrorCode
    OK              =   0
    ERROR           =  -1
    ENOTFOUND       =  -3
    EEXISTS         =  -4
    EAMBIGUOUS      =  -5
    EBUFS           =  -6
    EUSER           =  -7
    EBAREREPO       =  -8
    EUNBORNBRANCH   =  -9
    EUNMERGED       = -10
    ENONFASTFORWARD = -11
    EINVALIDSPEC    = -12
    ECONFLICT       = -13
    ELOCKED         = -14
    EMODIFIED       = -15
    EAUTH           = -16
    ECERTIFICATE    = -17
    EAPPLIED        = -18
    EPEEL           = -19
    EEOF            = -20
    EINVALID        = -21
    EUNCOMMITTED    = -22
    EDIRECTORY      = -23
    EMERGECONFLICT  = -24
    PASSTHROUGH     = -30
    ITEROVER        = -31
    RETRY           = -32
    EMISMATCH       = -33
    EINDEXDIRTY     = -34
    EAPPLYFAIL      = -35
    EOWNER          = -36
    TIMEOUT         = -37
    EUNCHANGED      = -38
    ENOTSUPPORTED   = -39
    EREADONLY       = -40
  end

  enum ErrorType
    NONE       = 0
    NOMEMORY
    OS
    INVALID
    REFERENCE
    ZLIB
    REPOSITORY
    CONFIG
    REGEX
    ODB
    INDEX
    OBJECT
    NET
    TAG
    TREE
    INDEXER
    SSL
    SUBMODULE
    THREAD
    STASH
    CHECKOUT
    FETCHHEAD
    MERGE
    SSH
    FILTER
    REVERT
    CALLBACK
    CHERRYPICK
    DESCRIBE
    REBASE
    FILESYSTEM
    PATCH
    WORKTREE
    SHA
    HTTP
    INTERNAL
    GRAFTS
  end

  struct Error
    message : LibC::Char*
    klass   : LibC::Int
  end

  fun err_last = git_error_last : Error*
  fun err_clear = git_error_clear
  fun err_set_str = git_error_set_str(error_class : LibC::Int, string : LibC::Char*) : LibC::Int
  fun err_set_oom = git_error_set_oom

  struct Buf
    ptr      : LibC::Char*
    reserved : LibC::SizeT
    size     : LibC::SizeT
  end

  fun buf_dispose = git_buf_dispose(buffer : Buf*)

  struct Strarray
    strings : LibC::Char**
    count   : LibC::SizeT
  end

  fun strarray_dispose = git_strarray_dispose(array : Strarray*)

  enum OidType
    SHA1   = 1
    SHA256 = 2
  end

  struct Oid
    id : StaticArray(UInt8, 20)
  end

  type OidShorten = Void*

  fun oid_fromstr = git_oid_fromstr(out_oid : Oid*, str : LibC::Char*) : LibC::Int
  fun oid_fromstrn = git_oid_fromstrn(out_oid : Oid*, str : LibC::Char*, length : LibC::SizeT) : LibC::Int
  fun oid_fromstrp = git_oid_fromstrp(out_oid : Oid*, str : LibC::Char*) : LibC::Int
  fun oid_fromraw = git_oid_fromraw(out_oid : Oid*, raw : UInt8*) : LibC::Int
  fun oid_fmt = git_oid_fmt(out_str : LibC::Char*, id : Oid*) : LibC::Int
  fun oid_nfmt = git_oid_nfmt(out_str : LibC::Char*, n : LibC::SizeT, id : Oid*) : LibC::Int
  fun oid_pathfmt = git_oid_pathfmt(out_str : LibC::Char*, id : Oid*) : LibC::Int
  fun oid_tostr_s = git_oid_tostr_s(oid : Oid*) : LibC::Char*
  fun oid_tostr = git_oid_tostr(out_str : LibC::Char*, n : LibC::SizeT, id : Oid*) : LibC::Char*
  fun oid_cpy = git_oid_cpy(out_oid : Oid*, src : Oid*) : LibC::Int
  fun oid_cmp = git_oid_cmp(a : Oid*, b : Oid*) : LibC::Int
  fun oid_equal = git_oid_equal(a : Oid*, b : Oid*) : LibC::Int
  fun oid_ncmp = git_oid_ncmp(a : Oid*, b : Oid*, len : LibC::SizeT) : LibC::Int
  fun oid_streq = git_oid_streq(id : Oid*, str : LibC::Char*) : LibC::Int
  fun oid_strcmp = git_oid_strcmp(id : Oid*, str : LibC::Char*) : LibC::Int
  fun oid_is_zero = git_oid_is_zero(id : Oid*) : LibC::Int

  fun oid_shorten_new = git_oid_shorten_new(min_length : LibC::SizeT) : OidShorten
  fun oid_shorten_add = git_oid_shorten_add(os         : OidShorten, text_id : LibC::Char*) : LibC::Int
  fun oid_shorten_free = git_oid_shorten_free(os : OidShorten)

  enum CredentialType
    USERPASS_PLAINTEXT =  1
    SSH_KEY            =  2
    SSH_CUSTOM         =  4
    DEFAULT            =  8
    SSH_INTERACTIVE    = 16
    USERNAME           = 32
    SSH_MEMORY         = 64
  end

  alias CredentialAcquireCb = (Credential*, LibC::Char*, LibC::Char*, LibC::UInt, Void* -> LibC::Int)
  alias CredentialSignCb = (Void*, LibC::Char**, LibC::SizeT*, LibC::Char*, LibC::SizeT, Void** -> LibC::Int)

  fun credential_free = git_credential_free(cred : Credential)
  fun credential_has_username = git_credential_has_username(cred : Credential) : LibC::Int
  fun credential_get_username = git_credential_get_username(cred : Credential) : LibC::Char*

  fun credential_userpass_plaintext_new = git_credential_userpass_plaintext_new(out_cred : Credential*, username : LibC::Char*, password : LibC::Char*) : LibC::Int
  fun credential_default_new = git_credential_default_new(out_cred : Credential*) : LibC::Int
  fun credential_username_new = git_credential_username_new(out_cred : Credential*, username : LibC::Char*) : LibC::Int

  fun credential_ssh_key_new = git_credential_ssh_key_new(out_cred : Credential*, username : LibC::Char*, publickey : LibC::Char*, privatekey : LibC::Char*, passphrase : LibC::Char*) : LibC::Int
  fun credential_ssh_key_memory_new = git_credential_ssh_key_memory_new(out_cred : Credential*, username : LibC::Char*, publickey : LibC::Char*, privatekey : LibC::Char*, passphrase : LibC::Char*) : LibC::Int
  fun credential_ssh_key_from_agent = git_credential_ssh_key_from_agent(out_cred : Credential*, username : LibC::Char*) : LibC::Int

  fun credential_ssh_custom_new = git_credential_ssh_custom_new(out_cred : Credential*, username : LibC::Char*, publickey : LibC::Char*, publickey_len : LibC::SizeT, sign_callback : CredentialSignCb, payload : Void*) : LibC::Int

  enum RepositoryOpenFlag : UInt32
    NO_SEARCH =  1
    CROSS_FS  =  2
    BARE      =  4
    NO_DOTGIT =  8
    FROM_ENV  = 16
  end

  enum RepositoryInitFlag : UInt32
    BARE              =  1
    NO_REINIT         =  2
    MKDIR             =  8
    MKPATH            = 16
    EXTERNAL_TEMPLATE = 32
    RELATIVE_GITLINK  = 64
  end

  enum RepositoryInitMode
    SHARED_UMASK =    0
    SHARED_GROUP = 1533
    SHARED_ALL   = 1535
  end

  struct RepositoryInitOptions
    version       : LibC::UInt
    flags         : UInt32
    mode          : UInt32
    workdir_path  : LibC::Char*
    description   : LibC::Char*
    template_path : LibC::Char*
    initial_head  : LibC::Char*
    origin_url    : LibC::Char*
    oid_type      : OidType
    refdb_type    : RefdbType
  end

  enum RepositoryItem
    GITDIR          =  0
    WORKDIR         =  1
    COMMONDIR       =  2
    INDEX           =  3
    OBJECTS         =  4
    REFS            =  5
    PACKED_REFS     =  6
    REMOTES         =  7
    CONFIG          =  8
    INFO            =  9
    HOOKS           = 10
    LOGS            = 11
    MODULES         = 12
    WORKTREES       = 13
    WORKTREE_CONFIG = 14
    LAST            = 15
  end

  enum RepositoryState
    NONE                    =  0
    MERGE                   =  1
    REVERT                  =  2
    REVERT_SEQUENCE         =  3
    CHERRYPICK              =  4
    CHERRYPICK_SEQUENCE     =  5
    BISECT                  =  6
    REBASE                  =  7
    REBASE_INTERACTIVE      =  8
    REBASE_MERGE            =  9
    APPLY_MAILBOX           = 10
    APPLY_MAILBOX_OR_REBASE = 11
  end

  alias RepositoryFetchheadForeachCb = (LibC::Char*, LibC::Char*, Oid*, LibC::UInt, Void* -> LibC::Int)
  alias RepositoryMergeheadForeachCb = (Oid*, Void* -> LibC::Int)

  fun repository_open = git_repository_open(out_repo : Repository*, path : LibC::Char*) : LibC::Int
  fun repository_open_from_worktree = git_repository_open_from_worktree(out_repo : Repository*, wt : Worktree) : LibC::Int
  fun repository_wrap_odb = git_repository_wrap_odb(out_repo : Repository*, odb : Odb) : LibC::Int
  fun repository_discover = git_repository_discover(out_buf : Buf*, start_path : LibC::Char*, across_fs : LibC::Int, ceiling_dirs : LibC::Char*) : LibC::Int
  fun repository_open_ext = git_repository_open_ext(out_repo : Repository*, path : LibC::Char*, flags : LibC::UInt, ceiling_dirs : LibC::Char*) : LibC::Int
  fun repository_open_bare = git_repository_open_bare(out_repo : Repository*, bare_path : LibC::Char*) : LibC::Int
  fun repository_free = git_repository_free(repo     : Repository)
  fun repository_init = git_repository_init(out_repo : Repository*, path : LibC::Char*, is_bare : LibC::UInt) : LibC::Int
  fun repository_init_options_init = git_repository_init_options_init(opts : RepositoryInitOptions*, version : LibC::UInt) : LibC::Int
  fun repository_init_ext = git_repository_init_ext(out_repo : Repository*, repo_path : LibC::Char*, opts : RepositoryInitOptions*) : LibC::Int
  fun repository_head = git_repository_head(out_ref : Reference*, repo : Repository) : LibC::Int
  fun repository_head_for_worktree = git_repository_head_for_worktree(out_ref : Reference*, repo : Repository, name : LibC::Char*) : LibC::Int
  fun repository_head_detached = git_repository_head_detached(repo : Repository) : LibC::Int
  fun repository_head_detached_for_worktree = git_repository_head_detached_for_worktree(repo : Repository, name : LibC::Char*) : LibC::Int
  fun repository_head_unborn = git_repository_head_unborn(repo : Repository) : LibC::Int
  fun repository_is_empty = git_repository_is_empty(repo : Repository) : LibC::Int
  fun repository_item_path = git_repository_item_path(out_buf : Buf*, repo : Repository, item : RepositoryItem) : LibC::Int
  fun repository_path = git_repository_path(repo : Repository) : LibC::Char*
  fun repository_workdir = git_repository_workdir(repo : Repository) : LibC::Char*
  fun repository_commondir = git_repository_commondir(repo : Repository) : LibC::Char*
  fun repository_set_workdir = git_repository_set_workdir(repo : Repository, workdir : LibC::Char*, update_gitlink : LibC::Int) : LibC::Int
  fun repository_is_bare = git_repository_is_bare(repo : Repository) : LibC::Int
  fun repository_is_worktree = git_repository_is_worktree(repo : Repository) : LibC::Int
  fun repository_config = git_repository_config(out_cfg : Config*, repo : Repository) : LibC::Int
  fun repository_config_snapshot = git_repository_config_snapshot(out_cfg : Config*, repo : Repository) : LibC::Int
  fun repository_odb = git_repository_odb(out_odb : Odb*, repo : Repository) : LibC::Int
  fun repository_refdb = git_repository_refdb(out_refdb : Refdb*, repo : Repository) : LibC::Int
  fun repository_index = git_repository_index(out_idx : Index*, repo : Repository) : LibC::Int
  fun repository_message = git_repository_message(out_buf : Buf*, repo : Repository) : LibC::Int
  fun repository_message_remove = git_repository_message_remove(repo : Repository) : LibC::Int
  fun repository_state_cleanup = git_repository_state_cleanup(repo : Repository) : LibC::Int
  fun repository_fetchhead_foreach = git_repository_fetchhead_foreach(repo : Repository, callback : RepositoryFetchheadForeachCb, payload : Void*) : LibC::Int
  fun repository_mergehead_foreach = git_repository_mergehead_foreach(repo : Repository, callback : RepositoryMergeheadForeachCb, payload : Void*) : LibC::Int
  fun repository_hashfile = git_repository_hashfile(out_oid : Oid*, repo : Repository, path : LibC::Char*, type : ObjectType, as_path : LibC::Char*) : LibC::Int
  fun repository_set_head = git_repository_set_head(repo : Repository, refname : LibC::Char*) : LibC::Int
  fun repository_set_head_detached = git_repository_set_head_detached(repo : Repository, committish : Oid*) : LibC::Int
  fun repository_set_head_detached_from_annotated = git_repository_set_head_detached_from_annotated(repo : Repository, committish : AnnotatedCommit) : LibC::Int
  fun repository_detach_head = git_repository_detach_head(repo : Repository) : LibC::Int
  fun repository_state = git_repository_state(repo : Repository) : LibC::Int
  fun repository_set_namespace = git_repository_set_namespace(repo : Repository, nmspace : LibC::Char*) : LibC::Int
  fun repository_get_namespace = git_repository_get_namespace(repo : Repository) : LibC::Char*
  fun repository_is_shallow = git_repository_is_shallow(repo : Repository) : LibC::Int
  fun repository_ident = git_repository_ident(out_name : LibC::Char**, out_email : LibC::Char**, repo : Repository) : LibC::Int
  fun repository_set_ident = git_repository_set_ident(repo : Repository, name : LibC::Char*, email : LibC::Char*) : LibC::Int
  fun repository_oid_type = git_repository_oid_type(repo : Repository) : OidType
  fun repository_commit_parents = git_repository_commit_parents(commits : CommitArray*, repo : Repository) : LibC::Int

  type Commitbuilder = Void*

  struct CommitHeader
    field : LibC::Char*
    value : LibC::Char*
  end

  alias CommitSignatureCb = (Commitbuilder, Repository, LibC::Char*, Void* -> LibC::Int)

  struct CommitCreateOptions
    version            : LibC::UInt
    allow_empty_commit : UInt32
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

  fun annotated_commit_from_ref = git_annotated_commit_from_ref(out_commit : AnnotatedCommit*, repo : Repository, ref : Reference) : LibC::Int
  fun annotated_commit_from_fetchhead = git_annotated_commit_from_fetchhead(out_commit : AnnotatedCommit*, repo : Repository, branch_name : LibC::Char*, remote_url : LibC::Char*, id : Oid*) : LibC::Int
  fun annotated_commit_lookup = git_annotated_commit_lookup(out_commit : AnnotatedCommit*, repo : Repository, id : Oid*) : LibC::Int
  fun annotated_commit_from_revspec = git_annotated_commit_from_revspec(out_commit : AnnotatedCommit*, repo : Repository, revspec : LibC::Char*) : LibC::Int
  fun annotated_commit_id = git_annotated_commit_id(commit : AnnotatedCommit) : Oid*
  fun annotated_commit_ref = git_annotated_commit_ref(commit : AnnotatedCommit) : LibC::Char*
  fun annotated_commit_free = git_annotated_commit_free(commit : AnnotatedCommit)

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

  enum TreewalkMode
    PRE  = 0
    POST = 1
  end

  enum TreeUpdateType
    UPSERT = 0
    REMOVE = 1
  end

  struct TreeUpdate
    action   : TreeUpdateType
    id       : Oid
    filemode : FilemodeType
    path     : LibC::Char*
  end

  alias TreebuilderFilterCb = (TreeEntry, Void* -> LibC::Int)
  alias TreewalkCb = (LibC::Char*, TreeEntry, Void* -> LibC::Int)

  fun tree_lookup = git_tree_lookup(out_tree : Tree*, repo : Repository, id : Oid*) : LibC::Int
  fun tree_lookup_prefix = git_tree_lookup_prefix(out_tree : Tree*, repo : Repository, id : Oid*, len : LibC::SizeT) : LibC::Int
  fun tree_free = git_tree_free(tree : Tree)
  fun tree_id = git_tree_id(tree : Tree) : Oid*
  fun tree_owner = git_tree_owner(tree : Tree) : Repository
  fun tree_entrycount = git_tree_entrycount(tree : Tree) : LibC::SizeT
  fun tree_entry_byname = git_tree_entry_byname(tree : Tree, filename : LibC::Char*) : TreeEntry
  fun tree_entry_byindex = git_tree_entry_byindex(tree : Tree, idx : LibC::SizeT) : TreeEntry
  fun tree_entry_byid = git_tree_entry_byid(tree : Tree, id : Oid*) : TreeEntry
  fun tree_entry_bypath = git_tree_entry_bypath(out_entry : TreeEntry*, root : Tree, path : LibC::Char*) : LibC::Int
  fun tree_entry_dup = git_tree_entry_dup(dest : TreeEntry*, source : TreeEntry) : LibC::Int
  fun tree_entry_free = git_tree_entry_free(entry : TreeEntry)
  fun tree_entry_name = git_tree_entry_name(entry : TreeEntry) : LibC::Char*
  fun tree_entry_id = git_tree_entry_id(entry : TreeEntry) : Oid*
  fun tree_entry_type = git_tree_entry_type(entry : TreeEntry) : ObjectType
  fun tree_entry_filemode = git_tree_entry_filemode(entry : TreeEntry) : FilemodeType
  fun tree_entry_filemode_raw = git_tree_entry_filemode_raw(entry : TreeEntry) : FilemodeType
  fun tree_entry_cmp = git_tree_entry_cmp(e1 : TreeEntry, e2 : TreeEntry) : LibC::Int
  fun tree_entry_to_object = git_tree_entry_to_object(object_out : Object*, repo : Repository, entry : TreeEntry) : LibC::Int

  fun treebuilder_new = git_treebuilder_new(out_bld : Treebuilder*, repo : Repository, source : Tree) : LibC::Int
  fun treebuilder_clear = git_treebuilder_clear(bld : Treebuilder) : LibC::Int
  fun treebuilder_entrycount = git_treebuilder_entrycount(bld : Treebuilder) : LibC::SizeT
  fun treebuilder_free = git_treebuilder_free(bld : Treebuilder)
  fun treebuilder_get = git_treebuilder_get(bld : Treebuilder, filename : LibC::Char*) : TreeEntry
  fun treebuilder_insert = git_treebuilder_insert(out_entry : TreeEntry*, bld : Treebuilder, filename : LibC::Char*, id : Oid*, filemode : FilemodeType) : LibC::Int
  fun treebuilder_remove = git_treebuilder_remove(bld : Treebuilder, filename : LibC::Char*) : LibC::Int
  fun treebuilder_filter = git_treebuilder_filter(bld : Treebuilder, filter : TreebuilderFilterCb, payload : Void*) : LibC::Int
  fun treebuilder_write = git_treebuilder_write(id : Oid*, bld : Treebuilder) : LibC::Int

  fun tree_walk = git_tree_walk(tree : Tree, mode : TreewalkMode, callback : TreewalkCb, payload : Void*) : LibC::Int
  fun tree_dup = git_tree_dup(out_tree : Tree*, source : Tree) : LibC::Int
  fun tree_create_updated = git_tree_create_updated(out_oid : Oid*, repo : Repository, baseline : Tree, nupdates : LibC::SizeT, updates : TreeUpdate*) : LibC::Int

  enum BlobFilterFlag : UInt32
    CHECK_FOR_BINARY       = 1
    NO_SYSTEM_ATTRIBUTES   = 2
    ATTRIBUTES_FROM_HEAD   = 4
    ATTRIBUTES_FROM_COMMIT = 8
  end

  struct BlobFilterOptions
    version        : LibC::Int
    flags          : UInt32
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

  type BranchIterator = Void*

  fun branch_create = git_branch_create(out_ref : Reference*, repo : Repository, branch_name : LibC::Char*, target : Commit, force : LibC::Int) : LibC::Int
  fun branch_create_from_annotated = git_branch_create_from_annotated(ref_out : Reference*, repo : Repository, branch_name : LibC::Char*, target : AnnotatedCommit, force : LibC::Int) : LibC::Int
  fun branch_delete = git_branch_delete(branch : Reference) : LibC::Int

  fun branch_iterator_new = git_branch_iterator_new(out_iter : BranchIterator*, repo : Repository, list_flags : BranchType) : LibC::Int
  fun branch_next = git_branch_next(out_ref : Reference*, out_type : BranchType*, iter : BranchIterator) : LibC::Int
  fun branch_iterator_free = git_branch_iterator_free(iter : BranchIterator)

  fun branch_move = git_branch_move(out_ref : Reference*, branch : Reference, new_branch_name : LibC::Char*, force : LibC::Int) : LibC::Int
  fun branch_lookup = git_branch_lookup(out_ref : Reference*, repo : Repository, branch_name : LibC::Char*, branch_type : BranchType) : LibC::Int
  fun branch_name = git_branch_name(out_name : LibC::Char**, ref : Reference) : LibC::Int

  fun branch_upstream = git_branch_upstream(out_ref : Reference*, branch : Reference) : LibC::Int
  fun branch_set_upstream = git_branch_set_upstream(branch : Reference, branch_name : LibC::Char*) : LibC::Int
  fun branch_upstream_name = git_branch_upstream_name(out_buf : Buf*, repo : Repository, refname : LibC::Char*) : LibC::Int

  fun branch_is_head = git_branch_is_head(branch : Reference) : LibC::Int
  fun branch_is_checked_out = git_branch_is_checked_out(branch : Reference) : LibC::Int

  fun branch_remote_name = git_branch_remote_name(out_buf : Buf*, repo : Repository, refname : LibC::Char*) : LibC::Int
  fun branch_upstream_remote = git_branch_upstream_remote(buf : Buf*, repo : Repository, refname : LibC::Char*) : LibC::Int
  fun branch_upstream_merge = git_branch_upstream_merge(buf : Buf*, repo : Repository, refname : LibC::Char*) : LibC::Int

  fun branch_name_is_valid = git_branch_name_is_valid(valid : LibC::Int*, name : LibC::Char*) : LibC::Int

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

  fun reference_delete = git_reference_delete(ref  : Reference) : LibC::Int
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

  struct IndexTime
    seconds     : Int32
    nanoseconds : UInt32
  end

  struct IndexEntry
    ctime          : IndexTime
    mtime          : IndexTime
    dev            : UInt32
    ino            : UInt32
    mode           : UInt32
    uid            : UInt32
    gid            : UInt32
    file_size      : UInt32
    id             : Oid
    flags          : UInt16
    flags_extended : UInt16
    path           : LibC::Char*
  end

  enum IndexEntryFlag
    EXTENDED = 16384
    VALID    = 32768
  end

  enum IndexEntryExtendedFlag
    INTENT_TO_ADD =  8192
    SKIP_WORKTREE = 16384
    UPTODATE      =     4
  end

  enum IndexCapability
    IGNORE_CASE =  1
    NO_FILEMODE =  2
    NO_SYMLINKS =  4
    FROM_OWNER  = -1
  end

  enum IndexAddOption
    DEFAULT                = 0
    FORCE                  = 1
    DISABLE_PATHSPEC_MATCH = 2
    CHECK_PATHSPEC         = 4
  end

  enum IndexStage
    ANY      = -1
    NORMAL   =  0
    ANCESTOR =  1
    OURS     =  2
    THEIRS   =  3
  end

  struct IndexOptions
    version  : LibC::UInt
    oid_type : OidType
  end

  alias IndexMatchedPathCb = (LibC::Char*, LibC::Char*, Void* -> LibC::Int)

  fun index_options_init = git_index_options_init(opts : IndexOptions*, version : LibC::UInt) : LibC::Int
  fun index_open = git_index_open(index_out : Index*, index_path : LibC::Char*) : LibC::Int
  fun index_open_ext = git_index_open_ext(index_out : Index*, index_path : LibC::Char*, opts : IndexOptions*) : LibC::Int
  fun index_new = git_index_new(index_out : Index*) : LibC::Int
  fun index_new_ext = git_index_new_ext(index_out : Index*, opts : IndexOptions*) : LibC::Int
  fun index_free = git_index_free(index : Index)
  fun index_owner = git_index_owner(index : Index) : Repository
  fun index_caps = git_index_caps(index : Index) : LibC::Int
  fun index_set_caps = git_index_set_caps(index : Index, caps : LibC::Int) : LibC::Int
  fun index_version = git_index_version(index : Index) : LibC::UInt
  fun index_set_version = git_index_set_version(index : Index, version : LibC::UInt) : LibC::Int
  fun index_read = git_index_read(index : Index, force : LibC::Int) : LibC::Int
  fun index_write = git_index_write(index : Index) : LibC::Int
  fun index_path = git_index_path(index : Index) : LibC::Char*
  fun index_read_tree = git_index_read_tree(index : Index, tree : Tree) : LibC::Int
  fun index_write_tree = git_index_write_tree(out_oid : Oid*, index : Index) : LibC::Int
  fun index_write_tree_to = git_index_write_tree_to(out_oid : Oid*, index : Index, repo : Repository) : LibC::Int
  fun index_entrycount = git_index_entrycount(index : Index) : LibC::SizeT
  fun index_clear = git_index_clear(index : Index) : LibC::Int
  fun index_get_byindex = git_index_get_byindex(index : Index, n : LibC::SizeT) : IndexEntry*
  fun index_get_bypath = git_index_get_bypath(index : Index, path : LibC::Char*, stage : LibC::Int) : IndexEntry*
  fun index_remove = git_index_remove(index : Index, path : LibC::Char*, stage : LibC::Int) : LibC::Int
  fun index_remove_directory = git_index_remove_directory(index : Index, dir : LibC::Char*, stage : LibC::Int) : LibC::Int
  fun index_add = git_index_add(index : Index, source_entry : IndexEntry*) : LibC::Int
  fun index_entry_stage = git_index_entry_stage(entry : IndexEntry*) : LibC::Int
  fun index_entry_is_conflict = git_index_entry_is_conflict(entry : IndexEntry*) : LibC::Int
  fun index_iterator_new = git_index_iterator_new(iterator_out : IndexIterator*, index : Index) : LibC::Int
  fun index_iterator_next = git_index_iterator_next(out_entry : IndexEntry**, iterator : IndexIterator) : LibC::Int
  fun index_iterator_free = git_index_iterator_free(iterator : IndexIterator)
  fun index_add_bypath = git_index_add_bypath(index : Index, path : LibC::Char*) : LibC::Int
  fun index_add_from_buffer = git_index_add_from_buffer(index : Index, entry : IndexEntry*, buffer : Void*, len : LibC::SizeT) : LibC::Int
  fun index_remove_bypath = git_index_remove_bypath(index : Index, path : LibC::Char*) : LibC::Int
  fun index_add_all = git_index_add_all(index : Index, pathspec : Strarray*, flags : LibC::UInt, callback : IndexMatchedPathCb, payload : Void*) : LibC::Int
  fun index_remove_all = git_index_remove_all(index : Index, pathspec : Strarray*, callback : IndexMatchedPathCb, payload : Void*) : LibC::Int
  fun index_update_all = git_index_update_all(index : Index, pathspec : Strarray*, callback : IndexMatchedPathCb, payload : Void*) : LibC::Int
  fun index_find = git_index_find(at_pos : LibC::SizeT*, index : Index, path : LibC::Char*) : LibC::Int
  fun index_find_prefix = git_index_find_prefix(at_pos : LibC::SizeT*, index : Index, prefix : LibC::Char*) : LibC::Int
  fun index_conflict_add = git_index_conflict_add(index : Index, ancestor_entry : IndexEntry*, our_entry : IndexEntry*, their_entry : IndexEntry*) : LibC::Int
  fun index_conflict_get = git_index_conflict_get(ancestor_out : IndexEntry**, our_out : IndexEntry**, their_out : IndexEntry**, index : Index, path : LibC::Char*) : LibC::Int
  fun index_conflict_remove = git_index_conflict_remove(index : Index, path : LibC::Char*) : LibC::Int
  fun index_conflict_cleanup = git_index_conflict_cleanup(index : Index) : LibC::Int
  fun index_has_conflicts = git_index_has_conflicts(index : Index) : LibC::Int
  fun index_conflict_iterator_new = git_index_conflict_iterator_new(iterator_out : IndexConflictIterator*, index : Index) : LibC::Int
  fun index_conflict_next = git_index_conflict_next(ancestor_out : IndexEntry**, our_out : IndexEntry**, their_out : IndexEntry**, iterator : IndexConflictIterator) : LibC::Int
  fun index_conflict_iterator_free = git_index_conflict_iterator_free(iterator : IndexConflictIterator)

  enum DiffOption : UInt32
    NORMAL                          =          0
    REVERSE                         =          1
    INCLUDE_IGNORED                 =          2
    RECURSE_IGNORED_DIRS            =          4
    INCLUDE_UNTRACKED               =          8
    RECURSE_UNTRACKED_DIRS          =         16
    INCLUDE_UNMODIFIED              =         32
    INCLUDE_TYPECHANGE              =         64
    INCLUDE_TYPECHANGE_TREES        =        128
    IGNORE_FILEMODE                 =        256
    IGNORE_SUBMODULES               =        512
    IGNORE_CASE                     =       1024
    INCLUDE_CASECHANGE              =       2048
    DISABLE_PATHSPEC_MATCH          =       4096
    SKIP_BINARY_CHECK               =       8192
    ENABLE_FAST_UNTRACKED_DIRS      =      16384
    UPDATE_INDEX                    =      32768
    INCLUDE_UNREADABLE              =      65536
    INCLUDE_UNREADABLE_AS_UNTRACKED =     131072
    INDENT_HEURISTIC                =     262144
    IGNORE_BLANK_LINES              =     524288
    FORCE_TEXT                      =    1048576
    FORCE_BINARY                    =    2097152
    IGNORE_WHITESPACE               =    4194304
    IGNORE_WHITESPACE_CHANGE        =    8388608
    IGNORE_WHITESPACE_EOL           =   16777216
    SHOW_UNTRACKED_CONTENT          =   33554432
    SHOW_UNMODIFIED                 =   67108864
    PATIENCE                        =  268435456
    MINIMAL                         =  536870912
    SHOW_BINARY                     = 1073741824
  end

  enum DiffFlag : UInt32
    BINARY     =  1
    NOT_BINARY =  2
    VALID_ID   =  4
    EXISTS     =  8
    VALID_SIZE = 16
  end

  enum DeltaType
    UNMODIFIED =  0
    ADDED      =  1
    DELETED    =  2
    MODIFIED   =  3
    RENAMED    =  4
    COPIED     =  5
    IGNORED    =  6
    UNTRACKED  =  7
    TYPECHANGE =  8
    UNREADABLE =  9
    CONFLICTED = 10
  end

  struct DiffFile
    id        : Oid
    path      : LibC::Char*
    size      : UInt64
    flags     : UInt32
    mode      : UInt16
    id_abbrev : UInt16
  end

  struct DiffDelta
    status     : DeltaType
    flags      : UInt32
    similarity : UInt16
    nfiles     : UInt16
    old_file   : DiffFile
    new_file   : DiffFile
  end

  alias DiffNotifyCb = (Diff, DiffDelta*, LibC::Char*, Void* -> LibC::Int)
  alias DiffProgressCb = (Diff, LibC::Char*, LibC::Char*, Void* -> LibC::Int)

  struct DiffOptions
    version           : LibC::UInt
    flags             : UInt32
    ignore_submodules : SubmoduleIgnoreType
    pathspec          : Strarray
    notify_cb         : DiffNotifyCb
    progress_cb       : DiffProgressCb
    payload           : Void*
    context_lines     : UInt32
    interhunk_lines   : UInt32
    oid_type          : OidType
    id_abbrev         : UInt16
    max_size          : Int64
    old_prefix        : LibC::Char*
    new_prefix        : LibC::Char*
  end

  struct DiffHunk
    old_start  : LibC::Int
    old_lines  : LibC::Int
    new_start  : LibC::Int
    new_lines  : LibC::Int
    header_len : LibC::SizeT
    header     : StaticArray(LibC::Char, 128)
  end

  struct DiffLine
    origin         : LibC::Char
    old_lineno     : LibC::Int
    new_lineno     : LibC::Int
    num_lines      : LibC::Int
    content_len    : LibC::SizeT
    content_offset : Int64
    content        : LibC::Char*
  end

  enum DiffFindOption : UInt32
    BY_CONFIG                       =     0
    RENAMES                         =     1
    RENAMES_FROM_REWRITES           =     2
    COPIES                          =     4
    COPIES_FROM_UNMODIFIED          =     8
    REWRITES                        =    16
    BREAK_REWRITES                  =    32
    FIND_AND_BREAK_REWRITES         =    48
    FOR_UNTRACKED                   =    64
    ALL                             =   255
    IGNORE_LEADING_WHITESPACE       =     0
    IGNORE_WHITESPACE               =  4096
    DONT_IGNORE_WHITESPACE          =  8192
    EXACT_MATCH_ONLY                = 16384
    BREAK_REWRITES_FOR_RENAMES_ONLY = 32768
    REMOVE_UNMODIFIED               = 65536
  end

  struct DiffFindOptions
    version                       : LibC::UInt
    flags                         : UInt32
    rename_threshold              : UInt16
    rename_from_rewrite_threshold : UInt16
    copy_threshold                : UInt16
    break_rewrite_threshold       : UInt16
    rename_limit                  : LibC::SizeT
    metric                        : Void*
  end

  enum DiffFormat
    PATCH        = 1
    PATCH_HEADER = 2
    RAW          = 3
    NAME_ONLY    = 4
    NAME_STATUS  = 5
    PATCH_ID     = 6
  end

  alias DiffFileCb = (DiffDelta*, LibC::Float, Void* -> LibC::Int)
  alias DiffBinaryCb = (DiffDelta*, Void*, Void* -> LibC::Int)
  alias DiffHunkCb = (DiffDelta*, DiffHunk*, Void* -> LibC::Int)
  alias DiffLineCb = (DiffDelta*, DiffHunk*, DiffLine*, Void* -> LibC::Int)

  fun diff_options_init = git_diff_options_init(opts : DiffOptions*, version : LibC::UInt) : LibC::Int
  fun diff_find_options_init = git_diff_find_options_init(opts : DiffFindOptions*, version : LibC::UInt) : LibC::Int
  fun diff_free = git_diff_free(diff : Diff)
  fun diff_tree_to_tree = git_diff_tree_to_tree(diff : Diff*, repo : Repository, old_tree : Tree, new_tree : Tree, opts : DiffOptions*) : LibC::Int
  fun diff_tree_to_index = git_diff_tree_to_index(diff : Diff*, repo : Repository, old_tree : Tree, index : Index, opts : DiffOptions*) : LibC::Int
  fun diff_index_to_workdir = git_diff_index_to_workdir(diff : Diff*, repo : Repository, index : Index, opts : DiffOptions*) : LibC::Int
  fun diff_tree_to_workdir = git_diff_tree_to_workdir(diff : Diff*, repo : Repository, old_tree : Tree, opts : DiffOptions*) : LibC::Int
  fun diff_tree_to_workdir_with_index = git_diff_tree_to_workdir_with_index(diff : Diff*, repo : Repository, old_tree : Tree, opts : DiffOptions*) : LibC::Int
  fun diff_index_to_index = git_diff_index_to_index(diff : Diff*, repo : Repository, old_index : Index, new_index : Index, opts : DiffOptions*) : LibC::Int
  fun diff_merge = git_diff_merge(onto : Diff, from : Diff) : LibC::Int
  fun diff_find_similar = git_diff_find_similar(diff : Diff, options : DiffFindOptions*) : LibC::Int
  fun diff_num_deltas = git_diff_num_deltas(diff : Diff) : LibC::SizeT
  fun diff_num_deltas_of_type = git_diff_num_deltas_of_type(diff : Diff, type : DeltaType) : LibC::SizeT
  fun diff_get_delta = git_diff_get_delta(diff : Diff, idx : LibC::SizeT) : DiffDelta*
  fun diff_is_sorted_icase = git_diff_is_sorted_icase(diff : Diff) : LibC::Int
  fun diff_foreach = git_diff_foreach(diff : Diff, file_cb : DiffFileCb, binary_cb : DiffBinaryCb, hunk_cb : DiffHunkCb, line_cb : DiffLineCb, payload : Void*) : LibC::Int
  fun diff_status_char = git_diff_status_char(status : DeltaType) : LibC::Char
  fun diff_print = git_diff_print(diff : Diff, format : DiffFormat, print_cb : DiffLineCb, payload : Void*) : LibC::Int
  fun diff_to_buf = git_diff_to_buf(out_buf : Buf*, diff : Diff, format : DiffFormat) : LibC::Int

  enum StatusType : UInt32
    CURRENT          =     0
    INDEX_NEW        =     1
    INDEX_MODIFIED   =     2
    INDEX_DELETED    =     4
    INDEX_RENAMED    =     8
    INDEX_TYPECHANGE =    16
    WT_NEW           =   128
    WT_MODIFIED      =   256
    WT_DELETED       =   512
    WT_TYPECHANGE    =  1024
    WT_RENAMED       =  2048
    WT_UNREADABLE    =  4096
    IGNORED          = 16384
    CONFLICTED       = 32768
  end

  enum StatusShow
    INDEX_AND_WORKDIR = 0
    INDEX_ONLY        = 1
    WORKDIR_ONLY      = 2
  end

  enum StatusOpt : UInt32
    INCLUDE_UNTRACKED               =     1
    INCLUDE_IGNORED                 =     2
    INCLUDE_UNMODIFIED              =     4
    EXCLUDE_SUBMODULES              =     8
    RECURSE_UNTRACKED_DIRS          =    16
    DISABLE_PATHSPEC_MATCH          =    32
    RECURSE_IGNORED_DIRS            =    64
    RENAMES_HEAD_TO_INDEX           =   128
    RENAMES_INDEX_TO_WORKDIR        =   256
    SORT_CASE_SENSITIVELY           =   512
    SORT_CASE_INSENSITIVELY         =  1024
    RENAMES_FROM_REWRITES           =  2048
    NO_REFRESH                      =  4096
    UPDATE_INDEX                    =  8192
    INCLUDE_UNREADABLE              = 16384
    INCLUDE_UNREADABLE_AS_UNTRACKED = 32768
  end

  struct StatusOptions
    version          : LibC::UInt
    show             : StatusShow
    flags            : UInt32
    pathspec         : Strarray
    baseline         : Tree
    rename_threshold : UInt16
  end

  struct StatusEntry
    status           : StatusType
    head_to_index    : DiffDelta*
    index_to_workdir : DiffDelta*
  end

  alias StatusCb = (LibC::Char*, LibC::UInt, Void* -> LibC::Int)

  fun status_options_init = git_status_options_init(opts : StatusOptions*, version : LibC::UInt) : LibC::Int
  fun status_foreach = git_status_foreach(repo : Repository, callback : StatusCb, payload : Void*) : LibC::Int
  fun status_foreach_ext = git_status_foreach_ext(repo : Repository, opts : StatusOptions*, callback : StatusCb, payload : Void*) : LibC::Int
  fun status_file = git_status_file(status_flags : LibC::UInt*, repo : Repository, path : LibC::Char*) : LibC::Int
  fun status_list_new = git_status_list_new(out_list : StatusList*, repo : Repository, opts : StatusOptions*) : LibC::Int
  fun status_list_entrycount = git_status_list_entrycount(statuslist : StatusList) : LibC::SizeT
  fun status_byindex = git_status_byindex(statuslist : StatusList, idx : LibC::SizeT) : StatusEntry*
  fun status_list_free = git_status_list_free(statuslist : StatusList)
  fun status_should_ignore = git_status_should_ignore(ignored : LibC::Int*, repo : Repository, path : LibC::Char*) : LibC::Int

  enum CheckoutStrategy : UInt32
    SAFE                         =          0
    FORCE                        =          2
    RECREATE_MISSING             =          4
    ALLOW_CONFLICTS              =         16
    REMOVE_UNTRACKED             =         32
    REMOVE_IGNORED               =         64
    UPDATE_ONLY                  =        128
    DONT_UPDATE_INDEX            =        256
    NO_REFRESH                   =        512
    SKIP_UNMERGED                =       1024
    USE_OURS                     =       2048
    USE_THEIRS                   =       4096
    DISABLE_PATHSPEC_MATCH       =       8192
    UPDATE_SUBMODULES            =      65536
    UPDATE_SUBMODULES_IF_CHANGED =     131072
    SKIP_LOCKED_DIRECTORIES      =     262144
    DONT_OVERWRITE_IGNORED       =     524288
    CONFLICT_STYLE_MERGE         =    1048576
    CONFLICT_STYLE_DIFF3         =    2097152
    DONT_REMOVE_EXISTING         =    4194304
    DONT_WRITE_INDEX             =    8388608
    DRY_RUN                      =   16777216
    CONFLICT_STYLE_ZDIFF3        =   33554432
    NONE                         = 1073741824
  end

  enum CheckoutNotify
    NONE      =     0
    CONFLICT  =     1
    DIRTY     =     2
    UPDATED   =     4
    UNTRACKED =     8
    IGNORED   =    16
    ALL       = 65535
  end

  alias CheckoutNotifyCb = (CheckoutNotify, LibC::Char*, DiffFile*, DiffFile*, DiffFile*, Void* -> LibC::Int)
  alias CheckoutProgressCb = (LibC::Char*, LibC::SizeT, LibC::SizeT, Void* -> Void)
  alias CheckoutPerfdataCb = (Void*, Void* -> Void)

  struct CheckoutOptions
    version           : LibC::UInt
    checkout_strategy : UInt32
    disable_filters   : LibC::Int
    dir_mode          : LibC::UInt
    file_mode         : LibC::UInt
    file_open_flags   : LibC::Int
    notify_flags      : LibC::UInt
    notify_cb         : CheckoutNotifyCb
    notify_payload    : Void*
    progress_cb       : CheckoutProgressCb
    progress_payload  : Void*
    paths             : Strarray
    baseline          : Tree
    baseline_index    : Index
    target_directory  : LibC::Char*
    ancestor_label    : LibC::Char*
    our_label         : LibC::Char*
    their_label       : LibC::Char*
    perfdata_cb       : CheckoutPerfdataCb
    perfdata_payload  : Void*
  end

  fun checkout_options_init = git_checkout_options_init(opts : CheckoutOptions*, version : LibC::UInt) : LibC::Int
  fun checkout_head = git_checkout_head(repo : Repository, opts : CheckoutOptions*) : LibC::Int
  fun checkout_index = git_checkout_index(repo : Repository, index : Index, opts : CheckoutOptions*) : LibC::Int
  fun checkout_tree = git_checkout_tree(repo : Repository, treeish : Object, opts : CheckoutOptions*) : LibC::Int

  enum ProxyType
    NONE      = 0
    AUTO      = 1
    SPECIFIED = 2
  end

  alias TransportCertificateCheckCb = (Cert, LibC::Int, LibC::Char*, Void* -> LibC::Int)

  struct ProxyOptions
    version           : LibC::UInt
    type              : ProxyType
    url               : LibC::Char*
    credentials       : CredentialAcquireCb
    certificate_check : TransportCertificateCheckCb
    payload           : Void*
  end

  fun proxy_options_init = git_proxy_options_init(opts : ProxyOptions*, version : LibC::UInt) : LibC::Int

  enum RemoteRedirect
    NONE    = 1
    INITIAL = 2
    ALL     = 4
  end

  enum FetchPrune
    UNSPECIFIED = 0
    PRUNE       = 1
    NO_PRUNE    = 2
  end

  enum RemoteAutotagOption
    UNSPECIFIED = 0
    AUTO        = 1
    NONE        = 2
    ALL         = 3
  end

  alias RemoteSidebandProgressCb = (LibC::Char*, LibC::Int, Void* -> LibC::Int)
  alias RemoteCompletionCb = (LibC::Int, Void* -> LibC::Int)
  alias TransferProgressCb = (Void*, Void* -> LibC::Int)
  alias UpdateTipsCb = (LibC::Char*, Oid*, Oid*, Void* -> LibC::Int)
  alias PackbuilderProgressCb = (LibC::Int, UInt32, UInt32, Void* -> LibC::Int)
  alias PushTransferProgressCb = (UInt32, UInt32, LibC::SizeT, Void* -> LibC::Int)
  alias PushUpdateReferenceCb = (LibC::Char*, LibC::Char*, Void* -> LibC::Int)
  alias PushNegotiationCb = (Void*, LibC::SizeT, Void* -> LibC::Int)
  alias TransportCb = (Transport*, Remote, Void* -> LibC::Int)
  alias RemoteReadyCb = (Remote, LibC::Int, Void* -> LibC::Int)
  alias ResolveUrlCb = (Buf*, LibC::Char*, LibC::Int, Void* -> LibC::Int)

  struct RemoteCallbacks
    version                : LibC::UInt
    sideband_progress      : RemoteSidebandProgressCb
    completion             : RemoteCompletionCb
    credentials            : CredentialAcquireCb
    certificate_check      : TransportCertificateCheckCb
    transfer_progress      : TransferProgressCb
    update_tips            : UpdateTipsCb
    pack_progress          : PackbuilderProgressCb
    push_transfer_progress : PushTransferProgressCb
    push_update_reference  : PushUpdateReferenceCb
    push_negotiation       : PushNegotiationCb
    transport              : TransportCb
    remote_ready           : RemoteReadyCb
    payload                : Void*
    resolve_url            : ResolveUrlCb
    update_refs            : Void*
  end

  struct FetchOptions
    version          : LibC::Int
    callbacks        : RemoteCallbacks
    prune            : FetchPrune
    update_fetchhead : LibC::UInt
    download_tags    : RemoteAutotagOption
    proxy_opts       : ProxyOptions
    depth            : LibC::Int
    follow_redirects : RemoteRedirect
    custom_headers   : Strarray
  end

  struct PushOptions
    version             : LibC::UInt
    pb_parallelism      : LibC::UInt
    callbacks           : RemoteCallbacks
    proxy_opts          : ProxyOptions
    follow_redirects    : RemoteRedirect
    custom_headers      : Strarray
    remote_push_options : Strarray
  end

  struct RemoteConnectOptions
    version          : LibC::UInt
    callbacks        : RemoteCallbacks
    proxy_opts       : ProxyOptions
    follow_redirects : RemoteRedirect
    custom_headers   : Strarray
  end

  fun remote_init_callbacks = git_remote_init_callbacks(opts : RemoteCallbacks*, version : LibC::UInt) : LibC::Int
  fun fetch_options_init = git_fetch_options_init(opts : FetchOptions*, version : LibC::UInt) : LibC::Int
  fun push_options_init = git_push_options_init(opts : PushOptions*, version : LibC::UInt) : LibC::Int
  fun remote_connect_options_init = git_remote_connect_options_init(opts : RemoteConnectOptions*, version : LibC::UInt) : LibC::Int

  enum CloneLocal
    AUTO           = 0
    LOCAL          = 1
    NO_LOCAL       = 2
    LOCAL_NO_LINKS = 3
  end

  struct CloneOptions
    version               : LibC::UInt
    checkout_opts         : CheckoutOptions
    fetch_opts            : FetchOptions
    bare                  : LibC::Int
    local                 : CloneLocal
    checkout_branch       : LibC::Char*
    repository_cb         : Void*
    repository_cb_payload : Void*
    remote_cb             : Void*
    remote_cb_payload     : Void*
  end

  fun clone_options_init = git_clone_options_init(opts : CloneOptions*, version : LibC::UInt) : LibC::Int
  fun clone = git_clone(out_repo : Repository*, url : LibC::Char*, local_path : LibC::Char*, options : CloneOptions*) : LibC::Int

  enum ConfigLevel
    SYSTEM        =  2
    XDG           =  3
    GLOBAL        =  4
    LOCAL         =  5
    WORKTREE      =  6
    APP           =  7
    HIGHEST_LEVEL = -1
  end

  struct ConfigEntry
    name          : LibC::Char*
    value         : LibC::Char*
    backend_type  : LibC::Char*
    origin_path   : LibC::Char*
    include_depth : LibC::UInt
    level         : ConfigLevel
  end

  type ConfigIterator = Void*

  alias ConfigForeachCb = (ConfigEntry*, Void* -> LibC::Int)

  fun config_entry_free = git_config_entry_free(entry : ConfigEntry*)

  fun config_find_global = git_config_find_global(out_buf : Buf*) : LibC::Int
  fun config_find_xdg = git_config_find_xdg(out_buf : Buf*) : LibC::Int
  fun config_find_system = git_config_find_system(out_buf : Buf*) : LibC::Int

  fun config_open_default = git_config_open_default(out_cfg : Config*) : LibC::Int
  fun config_new = git_config_new(out_cfg : Config*) : LibC::Int
  fun config_open_ondisk = git_config_open_ondisk(out_cfg : Config*, path : LibC::Char*) : LibC::Int
  fun config_open_level = git_config_open_level(out_cfg : Config*, parent : Config, level : ConfigLevel) : LibC::Int
  fun config_open_global = git_config_open_global(out_cfg : Config*, config : Config) : LibC::Int

  fun config_snapshot = git_config_snapshot(out_cfg : Config*, config : Config) : LibC::Int
  fun config_free = git_config_free(cfg : Config)

  fun config_get_entry = git_config_get_entry(out_entry : ConfigEntry**, cfg : Config, name : LibC::Char*) : LibC::Int
  fun config_get_int32 = git_config_get_int32(out_val : Int32*, cfg : Config, name : LibC::Char*) : LibC::Int
  fun config_get_int64 = git_config_get_int64(out_val : Int64*, cfg : Config, name : LibC::Char*) : LibC::Int
  fun config_get_bool = git_config_get_bool(out_val : LibC::Int*, cfg : Config, name : LibC::Char*) : LibC::Int
  fun config_get_path = git_config_get_path(out_buf : Buf*, cfg : Config, name : LibC::Char*) : LibC::Int
  fun config_get_string = git_config_get_string(out_val : LibC::Char**, cfg : Config, name : LibC::Char*) : LibC::Int
  fun config_get_string_buf = git_config_get_string_buf(out_buf : Buf*, cfg : Config, name : LibC::Char*) : LibC::Int

  fun config_set_int32 = git_config_set_int32(cfg : Config, name : LibC::Char*, value : Int32) : LibC::Int
  fun config_set_int64 = git_config_set_int64(cfg : Config, name : LibC::Char*, value : Int64) : LibC::Int
  fun config_set_bool = git_config_set_bool(cfg : Config, name : LibC::Char*, value : LibC::Int) : LibC::Int
  fun config_set_string = git_config_set_string(cfg : Config, name : LibC::Char*, value : LibC::Char*) : LibC::Int
  fun config_set_multivar = git_config_set_multivar(cfg : Config, name : LibC::Char*, regexp : LibC::Char*, value : LibC::Char*) : LibC::Int

  fun config_delete_entry = git_config_delete_entry(cfg : Config, name : LibC::Char*) : LibC::Int
  fun config_delete_multivar = git_config_delete_multivar(cfg : Config, name : LibC::Char*, regexp : LibC::Char*) : LibC::Int

  fun config_foreach = git_config_foreach(cfg : Config, callback : ConfigForeachCb, payload : Void*) : LibC::Int
  fun config_iterator_new = git_config_iterator_new(out_iter : ConfigIterator*, cfg : Config) : LibC::Int
  fun config_iterator_glob_new = git_config_iterator_glob_new(out_iter : ConfigIterator*, cfg : Config, regexp : LibC::Char*) : LibC::Int
  fun config_next = git_config_next(entry : ConfigEntry**, iter : ConfigIterator) : LibC::Int
  fun config_iterator_free = git_config_iterator_free(iter : ConfigIterator)

  enum SubmoduleStatus
    IN_HEAD           =    1
    IN_INDEX          =    2
    IN_CONFIG         =    4
    IN_WD             =    8
    INDEX_ADDED       =   16
    INDEX_DELETED     =   32
    INDEX_MODIFIED    =   64
    WD_UNINITIALIZED  =  128
    WD_ADDED          =  256
    WD_DELETED        =  512
    WD_MODIFIED       = 1024
    WD_INDEX_MODIFIED = 2048
    WD_WD_MODIFIED    = 4096
    WD_UNTRACKED      = 8192
  end

  struct SubmoduleUpdateOptions
    version       : LibC::UInt
    checkout_opts : CheckoutOptions
    fetch_opts    : FetchOptions
    allow_fetch   : LibC::Int
  end

  alias SubmoduleCb = (Submodule, LibC::Char*, Void* -> LibC::Int)

  fun submodule_update_options_init = git_submodule_update_options_init(opts : SubmoduleUpdateOptions*, version : LibC::UInt) : LibC::Int
  fun submodule_update = git_submodule_update(submodule : Submodule, init : LibC::Int, options : SubmoduleUpdateOptions*) : LibC::Int

  fun submodule_lookup = git_submodule_lookup(out_submodule : Submodule*, repo : Repository, name : LibC::Char*) : LibC::Int
  fun submodule_dup = git_submodule_dup(out_submodule : Submodule*, source : Submodule) : LibC::Int
  fun submodule_free = git_submodule_free(submodule : Submodule)

  fun submodule_foreach = git_submodule_foreach(repo : Repository, callback : SubmoduleCb, payload : Void*) : LibC::Int
  fun submodule_add_setup = git_submodule_add_setup(out_submodule : Submodule*, repo : Repository, url : LibC::Char*, path : LibC::Char*, use_gitlink : LibC::Int) : LibC::Int
  fun submodule_clone = git_submodule_clone(out_repo : Repository*, submodule : Submodule, opts : SubmoduleUpdateOptions*) : LibC::Int
  fun submodule_add_finalize = git_submodule_add_finalize(submodule : Submodule) : LibC::Int
  fun submodule_add_to_index = git_submodule_add_to_index(submodule : Submodule, write_index : LibC::Int) : LibC::Int

  fun submodule_owner = git_submodule_owner(submodule : Submodule) : Repository
  fun submodule_name = git_submodule_name(submodule : Submodule) : LibC::Char*
  fun submodule_path = git_submodule_path(submodule : Submodule) : LibC::Char*
  fun submodule_url = git_submodule_url(submodule : Submodule) : LibC::Char*
  fun submodule_resolve_url = git_submodule_resolve_url(out_buf : Buf*, repo : Repository, url : LibC::Char*) : LibC::Int
  fun submodule_branch = git_submodule_branch(submodule : Submodule) : LibC::Char*

  fun submodule_set_branch = git_submodule_set_branch(repo : Repository, name : LibC::Char*, branch : LibC::Char*) : LibC::Int
  fun submodule_set_url = git_submodule_set_url(repo : Repository, name : LibC::Char*, url : LibC::Char*) : LibC::Int

  fun submodule_index_id = git_submodule_index_id(submodule : Submodule) : Oid*
  fun submodule_head_id = git_submodule_head_id(submodule : Submodule) : Oid*
  fun submodule_wd_id = git_submodule_wd_id(submodule : Submodule) : Oid*

  fun submodule_ignore = git_submodule_ignore(submodule : Submodule) : SubmoduleIgnoreType
  fun submodule_set_ignore = git_submodule_set_ignore(repo : Repository, name : LibC::Char*, ignore : SubmoduleIgnoreType) : LibC::Int

  fun submodule_update_strategy = git_submodule_update_strategy(submodule : Submodule) : SubmoduleUpdateType
  fun submodule_set_update = git_submodule_set_update(repo : Repository, name : LibC::Char*, update : SubmoduleUpdateType) : LibC::Int

  fun submodule_fetch_recurse_submodules = git_submodule_fetch_recurse_submodules(submodule : Submodule) : SubmoduleRecurseType
  fun submodule_set_fetch_recurse_submodules = git_submodule_set_fetch_recurse_submodules(repo : Repository, name : LibC::Char*, fetch_recurse_submodules : SubmoduleRecurseType) : LibC::Int

  fun submodule_init = git_submodule_init(submodule : Submodule, overwrite : LibC::Int) : LibC::Int
  fun submodule_repo_init = git_submodule_repo_init(out_repo : Repository*, sm : Submodule, use_gitlink : LibC::Int) : LibC::Int
  fun submodule_sync = git_submodule_sync(submodule : Submodule) : LibC::Int
  fun submodule_open = git_submodule_open(out_repo  : Repository*, submodule : Submodule) : LibC::Int
  fun submodule_reload = git_submodule_reload(submodule : Submodule, force : LibC::Int) : LibC::Int

  fun submodule_status = git_submodule_status(out_status : LibC::UInt*, repo : Repository, name : LibC::Char*, ignore : SubmoduleIgnoreType) : LibC::Int
  fun submodule_location = git_submodule_location(out_location_status : LibC::UInt*, submodule : Submodule) : LibC::Int

  fun signature_new = git_signature_new(out_sig : Signature**, name : LibC::Char*, email : LibC::Char*, time : Int64, offset : LibC::Int) : LibC::Int
  fun signature_now = git_signature_now(out_sig : Signature**, name : LibC::Char*, email : LibC::Char*) : LibC::Int
  fun signature_default_from_env = git_signature_default_from_env(author_out : Signature**, committer_out : Signature**, repo : Repository) : LibC::Int
  fun signature_default = git_signature_default(out_sig : Signature**, repo : Repository) : LibC::Int
  fun signature_from_buffer = git_signature_from_buffer(out_sig : Signature**, buf : LibC::Char*) : LibC::Int
  fun signature_dup = git_signature_dup(dest : Signature**, sig : Signature*) : LibC::Int
  fun signature_free = git_signature_free(sig : Signature*)

  enum MergeFlag : UInt32
    FIND_RENAMES     =  1
    FAIL_ON_CONFLICT =  2
    SKIP_REUC        =  4
    NO_RECURSIVE     =  8
    VIRTUAL_BASE     = 16
  end

  enum MergeFileFavor
    NORMAL = 0
    OURS   = 1
    THEIRS = 2
    UNION  = 3
  end

  enum MergeFileFlag : UInt32
    DEFAULT                  =   0
    STYLE_MERGE              =   1
    STYLE_DIFF3              =   2
    SIMPLIFY_ALNUM           =   4
    IGNORE_WHITESPACE        =   8
    IGNORE_WHITESPACE_CHANGE =  16
    IGNORE_WHITESPACE_EOL    =  32
    DIFF_PATIENCE            =  64
    DIFF_MINIMAL             = 128
    STYLE_ZDIFF3             = 256
    ACCEPT_CONFLICTS         = 512
  end

  struct MergeFileInput
    version : LibC::UInt
    ptr     : LibC::Char*
    size    : LibC::SizeT
    path    : LibC::Char*
    mode    : LibC::UInt
  end

  struct MergeFileOptions
    version        : LibC::UInt
    ancestor_label : LibC::Char*
    our_label      : LibC::Char*
    their_label    : LibC::Char*
    favor          : MergeFileFavor
    flags          : UInt32
    marker_size    : LibC::UShort
  end

  struct MergeFileResult
    automergeable : LibC::UInt
    path          : LibC::Char*
    mode          : LibC::UInt
    ptr           : LibC::Char*
    len           : LibC::SizeT
  end

  enum MergeAnalysis
    NONE        = 0
    NORMAL      = 1
    UP_TO_DATE  = 2
    FASTFORWARD = 4
    UNBORN      = 8
  end

  enum MergePreference
    NONE             = 0
    NO_FASTFORWARD   = 1
    FASTFORWARD_ONLY = 2
  end

  struct MergeOptions
    version          : LibC::UInt
    flags            : UInt32
    rename_threshold : UInt32
    target_limit     : UInt32
    metric           : Void*
    recursion_limit  : LibC::UInt
    default_driver   : LibC::Char*
    file_favor       : MergeFileFavor
    file_flags       : UInt32
  end

  fun merge_options_init = git_merge_options_init(opts : MergeOptions*, version : LibC::UInt) : LibC::Int
  fun merge_file_input_init = git_merge_file_input_init(opts : MergeFileInput*, version : LibC::UInt) : LibC::Int
  fun merge_file_options_init = git_merge_file_options_init(opts : MergeFileOptions*, version : LibC::UInt) : LibC::Int

  fun merge_analysis = git_merge_analysis(analysis_out : MergeAnalysis*, preference_out : MergePreference*, repo : Repository, their_heads : AnnotatedCommit*, their_heads_len : LibC::SizeT) : LibC::Int
  fun merge_analysis_for_ref = git_merge_analysis_for_ref(analysis_out : MergeAnalysis*, preference_out : MergePreference*, repo : Repository, our_ref : Reference, their_heads : AnnotatedCommit*, their_heads_len : LibC::SizeT) : LibC::Int

  fun merge_base = git_merge_base(out_oid : Oid*, repo : Repository, one : Oid*, two : Oid*) : LibC::Int
  fun merge_bases = git_merge_bases(out_array : Void*, repo : Repository, one : Oid*, two : Oid*) : LibC::Int
  fun merge_base_many = git_merge_base_many(out_oid : Oid*, repo : Repository, length : LibC::SizeT, input_array : Oid*) : LibC::Int
  fun merge_bases_many = git_merge_bases_many(out_array : Void*, repo : Repository, length : LibC::SizeT, input_array : Oid*) : LibC::Int
  fun merge_base_octopus = git_merge_base_octopus(out_oid : Oid*, repo : Repository, length : LibC::SizeT, input_array : Oid*) : LibC::Int

  fun merge_file = git_merge_file(out_res : MergeFileResult*, ancestor : MergeFileInput*, ours : MergeFileInput*, theirs : MergeFileInput*, opts : MergeFileOptions*) : LibC::Int
  fun merge_file_from_index = git_merge_file_from_index(out_res : MergeFileResult*, repo : Repository, ancestor : IndexEntry*, ours : IndexEntry*, theirs : IndexEntry*, opts : MergeFileOptions*) : LibC::Int
  fun merge_file_result_free = git_merge_file_result_free(result : MergeFileResult*)

  fun merge_trees = git_merge_trees(out_idx : Index*, repo : Repository, ancestor_tree : Tree, our_tree : Tree, their_tree : Tree, opts : MergeOptions*) : LibC::Int
  fun merge_commits = git_merge_commits(out_idx : Index*, repo : Repository, our_commit : Commit, their_commit : Commit, opts : MergeOptions*) : LibC::Int

  enum RebaseOperationType
    PICK   = 0
    REWORD = 1
    EDIT   = 2
    SQUASH = 3
    FIXUP  = 4
    EXEC   = 5
  end

  struct RebaseOperation
    type : RebaseOperationType
    id   : Oid
    exec : LibC::Char*
  end

  struct RebaseOptions
    version           : LibC::UInt
    quiet             : LibC::Int
    inmemory          : LibC::Int
    rewrite_notes_ref : LibC::Char*
    merge_options     : MergeOptions
    checkout_options  : CheckoutOptions
    commit_create_cb  : CommitCreateCb
    signing_cb        : Void*
    payload           : Void*
  end

  fun rebase_options_init = git_rebase_options_init(opts : RebaseOptions*, version : LibC::UInt) : LibC::Int
  fun rebase_init = git_rebase_init(out_rebase : Rebase*, repo : Repository, branch : AnnotatedCommit, upstream : AnnotatedCommit, onto : AnnotatedCommit, opts : RebaseOptions*) : LibC::Int
  fun rebase_open = git_rebase_open(out_rebase : Rebase*, repo : Repository, opts : RebaseOptions*) : LibC::Int

  fun rebase_orig_head_name = git_rebase_orig_head_name(rebase : Rebase) : LibC::Char*
  fun rebase_orig_head_id = git_rebase_orig_head_id(rebase : Rebase) : Oid*
  fun rebase_onto_name = git_rebase_onto_name(rebase : Rebase) : LibC::Char*
  fun rebase_onto_id = git_rebase_onto_id(rebase : Rebase) : Oid*

  fun rebase_operation_entrycount = git_rebase_operation_entrycount(rebase : Rebase) : LibC::SizeT
  fun rebase_operation_current = git_rebase_operation_current(rebase : Rebase) : LibC::SizeT
  fun rebase_operation_byindex = git_rebase_operation_byindex(rebase : Rebase, idx : LibC::SizeT) : RebaseOperation*

  fun rebase_next = git_rebase_next(operation : RebaseOperation**, rebase : Rebase) : LibC::Int
  fun rebase_inmemory_index = git_rebase_inmemory_index(index : Index*, rebase : Rebase) : LibC::Int
  fun rebase_commit = git_rebase_commit(id : Oid*, rebase : Rebase, author : Signature*, committer : Signature*, message_encoding : LibC::Char*, message : LibC::Char*) : LibC::Int
  fun rebase_abort = git_rebase_abort(rebase : Rebase) : LibC::Int
  fun rebase_finish = git_rebase_finish(rebase : Rebase, signature : Signature*) : LibC::Int
  fun rebase_free = git_rebase_free(rebase : Rebase)

  enum StashFlags : UInt32
    DEFAULT           = 0
    KEEP_INDEX        = 1
    INCLUDE_UNTRACKED = 2
    INCLUDE_IGNORED   = 4
    KEEP_ALL          = 8
  end

  struct StashSaveOptions
    version : LibC::UInt
    flags   : UInt32
    stasher : Signature*
    message : LibC::Char*
    paths   : Strarray
  end

  enum StashApplyFlags : UInt32
    DEFAULT         = 0
    REINSTATE_INDEX = 1
  end

  enum StashApplyProgress
    NONE               = 0
    LOADING_STASH      = 1
    ANALYZE_INDEX      = 2
    ANALYZE_MODIFIED   = 3
    ANALYZE_UNTRACKED  = 4
    CHECKOUT_UNTRACKED = 5
    CHECKOUT_MODIFIED  = 6
    DONE               = 7
  end

  alias StashApplyProgressCb = (StashApplyProgress, Void* -> LibC::Int)

  struct StashApplyOptions
    version          : LibC::UInt
    flags            : UInt32
    checkout_options : CheckoutOptions
    progress_cb      : StashApplyProgressCb
    progress_payload : Void*
  end

  alias StashCb = (LibC::SizeT, LibC::Char*, Oid*, Void* -> LibC::Int)

  fun stash_save = git_stash_save(out_oid : Oid*, repo : Repository, stasher : Signature*, message : LibC::Char*, flags : UInt32) : LibC::Int
  fun stash_save_options_init = git_stash_save_options_init(opts : StashSaveOptions*, version : LibC::UInt) : LibC::Int
  fun stash_save_with_opts = git_stash_save_with_opts(out_oid : Oid*, repo : Repository, opts : StashSaveOptions*) : LibC::Int

  fun stash_apply_options_init = git_stash_apply_options_init(opts : StashApplyOptions*, version : LibC::UInt) : LibC::Int
  fun stash_apply = git_stash_apply(repo : Repository, index : LibC::SizeT, options : StashApplyOptions*) : LibC::Int
  fun stash_foreach = git_stash_foreach(repo : Repository, callback : StashCb, payload : Void*) : LibC::Int
  fun stash_drop = git_stash_drop(repo : Repository, index : LibC::SizeT) : LibC::Int
  fun stash_pop = git_stash_pop(repo : Repository, index : LibC::SizeT, options : StashApplyOptions*) : LibC::Int

  enum ResetType
    SOFT  = 1
    MIXED = 2
    HARD  = 3
  end

  fun reset_default = git_reset_default(repo : Repository, target : Object, pathspecs : Strarray*) : LibC::Int
  fun reset_from_annotated = git_reset_from_annotated(repo : Repository, target : AnnotatedCommit, reset_type : ResetType, checkout_opts : CheckoutOptions*) : LibC::Int

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

  fun reflog_read = git_reflog_read(out_reflog : Reflog*, repo : Repository, name : LibC::Char*) : LibC::Int
  fun reflog_write = git_reflog_write(reflog : Reflog) : LibC::Int
  fun reflog_append = git_reflog_append(reflog : Reflog, id : Oid*, committer : Signature*, msg : LibC::Char*) : LibC::Int
  fun reflog_rename = git_reflog_rename(repo : Repository, old_name : LibC::Char*, name : LibC::Char*) : LibC::Int
  fun reflog_delete = git_reflog_delete(repo : Repository, name : LibC::Char*) : LibC::Int

  fun reflog_entrycount = git_reflog_entrycount(reflog : Reflog) : LibC::SizeT
  fun reflog_entry_byindex = git_reflog_entry_byindex(reflog : Reflog, idx : LibC::SizeT) : ReflogEntry*
  fun reflog_drop = git_reflog_drop(reflog : Reflog, idx : LibC::SizeT, rewrite_previous_entry : LibC::Int) : LibC::Int

  fun reflog_entry_id_old = git_reflog_entry_id_old(entry : ReflogEntry*) : Oid*
  fun reflog_entry_id_new = git_reflog_entry_id_new(entry : ReflogEntry*) : Oid*
  fun reflog_entry_committer = git_reflog_entry_committer(entry : ReflogEntry*) : Signature*
  fun reflog_entry_message = git_reflog_entry_message(entry : ReflogEntry*) : LibC::Char*

  fun reflog_free = git_reflog_free(reflog : Reflog)

  enum BlameFlag : UInt32
    NORMAL                          =  0
    TRACK_COPIES_SAME_FILE          =  1
    TRACK_COPIES_SAME_COMMIT_MOVES  =  2
    TRACK_COPIES_SAME_COMMIT_COPIES =  4
    TRACK_COPIES_ANY_COMMIT_COPIES  =  8
    FIRST_PARENT                    = 16
    USE_MAILMAP                     = 32
    IGNORE_WHITESPACE               = 64
  end

  struct BlameOptions
    version              : LibC::UInt
    flags                : UInt32
    min_match_characters : UInt16
    newest_commit        : Oid
    oldest_commit        : Oid
    min_line             : LibC::SizeT
    max_line             : LibC::SizeT
  end

  struct BlameHunk
    lines_in_hunk           : LibC::SizeT
    final_commit_id         : Oid
    final_start_line_number : LibC::SizeT
    final_signature         : Signature*
    final_committer         : Signature*
    orig_commit_id          : Oid
    orig_path               : LibC::Char*
    orig_start_line_number  : LibC::SizeT
    orig_signature          : Signature*
    orig_committer          : Signature*
    summary                 : LibC::Char*
    boundary                : LibC::Char
  end

  struct BlameLine
    ptr : LibC::Char*
    len : LibC::SizeT
  end

  fun blame_options_init = git_blame_options_init(opts : BlameOptions*, version : LibC::UInt) : LibC::Int

  fun blame_linecount = git_blame_linecount(blame : Blame) : LibC::SizeT
  fun blame_hunkcount = git_blame_hunkcount(blame : Blame) : LibC::SizeT
  fun blame_hunk_byindex = git_blame_hunk_byindex(blame : Blame, index : LibC::SizeT) : BlameHunk*
  fun blame_hunk_byline = git_blame_hunk_byline(blame : Blame, lineno : LibC::SizeT) : BlameHunk*
  fun blame_line_byindex = git_blame_line_byindex(blame : Blame, idx : LibC::SizeT) : BlameLine*

  fun blame_file = git_blame_file(out_blame : Blame*, repo : Repository, path : LibC::Char*, options : BlameOptions*) : LibC::Int
  fun blame_file_from_buffer = git_blame_file_from_buffer(out_blame : Blame*, repo : Repository, path : LibC::Char*, contents : LibC::Char*, contents_len : LibC::SizeT, options : BlameOptions*) : LibC::Int
  fun blame_buffer = git_blame_buffer(out_blame : Blame*, base : Blame, buffer : LibC::Char*, buffer_len : LibC::SizeT) : LibC::Int
  fun blame_free = git_blame_free(blame : Blame)

  struct WorktreeAddOptions
    version           : LibC::UInt
    lock              : LibC::Int
    checkout_existing : LibC::Int
    ref               : Reference
    checkout_options  : CheckoutOptions
  end

  enum WorktreePruneType
    VALID        = 1
    LOCKED       = 2
    WORKING_TREE = 4
  end

  struct WorktreePruneOptions
    version : LibC::UInt
    flags   : UInt32
  end

  fun worktree_list = git_worktree_list(out_array : Strarray*, repo : Repository) : LibC::Int
  fun worktree_lookup = git_worktree_lookup(out_wt : Worktree*, repo : Repository, name : LibC::Char*) : LibC::Int
  fun worktree_open_from_repository = git_worktree_open_from_repository(out_wt : Worktree*, repo : Repository) : LibC::Int
  fun worktree_free = git_worktree_free(wt : Worktree)
  fun worktree_validate = git_worktree_validate(wt : Worktree) : LibC::Int

  fun worktree_add_options_init = git_worktree_add_options_init(opts : WorktreeAddOptions*, version : LibC::UInt) : LibC::Int
  fun worktree_add = git_worktree_add(out_wt : Worktree*, repo : Repository, name : LibC::Char*, path : LibC::Char*, opts : WorktreeAddOptions*) : LibC::Int

  fun worktree_lock = git_worktree_lock(wt : Worktree, reason : LibC::Char*) : LibC::Int
  fun worktree_unlock = git_worktree_unlock(wt : Worktree) : LibC::Int
  fun worktree_is_locked = git_worktree_is_locked(reason : Buf*, wt : Worktree) : LibC::Int

  fun worktree_name = git_worktree_name(wt : Worktree) : LibC::Char*
  fun worktree_path = git_worktree_path(wt : Worktree) : LibC::Char*

  fun worktree_prune_options_init = git_worktree_prune_options_init(opts : WorktreePruneOptions*, version : LibC::UInt) : LibC::Int
  fun worktree_is_prunable = git_worktree_is_prunable(wt : Worktree, opts : WorktreePruneOptions*) : LibC::Int
  fun worktree_prune = git_worktree_prune(wt : Worktree, opts : WorktreePruneOptions*) : LibC::Int

  fun patch_owner = git_patch_owner(patch : Patch) : Repository
  fun patch_from_diff = git_patch_from_diff(out_patch : Patch*, diff : Diff, idx : LibC::SizeT) : LibC::Int
  fun patch_from_blobs = git_patch_from_blobs(out_patch : Patch*, old_blob : Blob, old_as_path : LibC::Char*, new_blob : Blob, new_as_path : LibC::Char*, opts : DiffOptions*) : LibC::Int
  fun patch_from_blob_and_buffer = git_patch_from_blob_and_buffer(out_patch : Patch*, old_blob : Blob, old_as_path : LibC::Char*, buffer : Void*, buffer_len : LibC::SizeT, buffer_as_path : LibC::Char*, opts : DiffOptions*) : LibC::Int
  fun patch_from_buffers = git_patch_from_buffers(out_patch : Patch*, old_buffer : Void*, old_len : LibC::SizeT, old_as_path : LibC::Char*, new_buffer : Void*, new_len : LibC::SizeT, new_as_path : LibC::Char*, opts : DiffOptions*) : LibC::Int
  fun patch_free = git_patch_free(patch : Patch)

  fun patch_get_delta = git_patch_get_delta(patch : Patch) : DiffDelta*
  fun patch_num_hunks = git_patch_num_hunks(patch : Patch) : LibC::SizeT
  fun patch_line_stats = git_patch_line_stats(total_context : LibC::SizeT*, total_additions : LibC::SizeT*, total_deletions : LibC::SizeT*, patch : Patch) : LibC::Int
  fun patch_get_hunk = git_patch_get_hunk(out_hunk : DiffHunk**, lines_in_hunk : LibC::SizeT*, patch : Patch, hunk_idx : LibC::SizeT) : LibC::Int
  fun patch_num_lines_in_hunk = git_patch_num_lines_in_hunk(patch : Patch, hunk_idx : LibC::SizeT) : LibC::Int
  fun patch_get_line_in_hunk = git_patch_get_line_in_hunk(out_line : DiffLine**, patch : Patch, hunk_idx : LibC::SizeT, line_of_hunk : LibC::SizeT) : LibC::Int
  fun patch_size = git_patch_size(patch : Patch, include_context : LibC::Int, include_hunk_headers : LibC::Int, include_file_headers : LibC::Int) : LibC::SizeT
  fun patch_print = git_patch_print(patch : Patch, print_cb : DiffLineCb, payload : Void*) : LibC::Int
  fun patch_to_buf = git_patch_to_buf(out_buf : Buf*, patch : Patch) : LibC::Int

  enum RevspecType
    SINGLE     = 1
    RANGE      = 2
    MERGE_BASE = 4
  end

  struct Revspec
    from  : Object
    to    : Object
    flags : LibC::UInt
  end

  fun revparse_single = git_revparse_single(out_obj : Object*, repo : Repository, spec : LibC::Char*) : LibC::Int
  fun revparse_ext = git_revparse_ext(object_out : Object*, reference_out : Reference*, repo : Repository, spec : LibC::Char*) : LibC::Int
  fun revparse = git_revparse(revspec : Revspec*, repo : Repository, spec : LibC::Char*) : LibC::Int

  fun graph_ahead_behind = git_graph_ahead_behind(ahead : LibC::SizeT*, behind : LibC::SizeT*, repo : Repository, local : Oid*, upstream : Oid*) : LibC::Int
  fun graph_descendant_of = git_graph_descendant_of(repo : Repository, commit : Oid*, ancestor : Oid*) : LibC::Int
  fun graph_reachable_from_any = git_graph_reachable_from_any(repo : Repository, commit : Oid*, descendant_array : Oid*, length : LibC::SizeT) : LibC::Int

  struct CommitGraphOpenOptions
    version  : LibC::UInt
    oid_type : OidType
  end

  enum CommitGraphSplitStrategy
    SINGLE_FILE = 0
  end

  struct CommitGraphWriterOptions
    version        : LibC::UInt
    oid_type       : OidType
    split_strategy : CommitGraphSplitStrategy
    size_multiple  : LibC::Float
    max_commits    : LibC::SizeT
  end

  fun commit_graph_open_options_init = git_commit_graph_open_options_init(opts : CommitGraphOpenOptions*, version : LibC::UInt) : LibC::Int
  fun commit_graph_open = git_commit_graph_open(cgraph_out : CommitGraph*, objects_dir : LibC::Char*, options : CommitGraphOpenOptions*) : LibC::Int
  fun commit_graph_free = git_commit_graph_free(cgraph : CommitGraph)

  fun commit_graph_writer_options_init = git_commit_graph_writer_options_init(opts : CommitGraphWriterOptions*, version : LibC::UInt) : LibC::Int
  fun commit_graph_writer_new = git_commit_graph_writer_new(out : CommitGraphWriter*, objects_info_dir : LibC::Char*, options : CommitGraphWriterOptions*) : LibC::Int
  fun commit_graph_writer_free = git_commit_graph_writer_free(w : CommitGraphWriter)
  fun commit_graph_writer_add_index_file = git_commit_graph_writer_add_index_file(w : CommitGraphWriter, repo : Repository, idx_path : LibC::Char*) : LibC::Int
  fun commit_graph_writer_add_revwalk = git_commit_graph_writer_add_revwalk(w : CommitGraphWriter, walk : Revwalk) : LibC::Int
  fun commit_graph_writer_commit = git_commit_graph_writer_commit(w : CommitGraphWriter) : LibC::Int
  fun commit_graph_writer_dump = git_commit_graph_writer_dump(buffer : Buf*, w : CommitGraphWriter) : LibC::Int

  @[Flags]
  enum Sort : UInt32
    NONE        = 0
    TOPOLOGICAL = 1
    TIME        = 2
    REVERSE     = 4
  end

  alias RevwalkHideCb = (Oid*, Void* -> LibC::Int)

  fun revwalk_new = git_revwalk_new(out : Revwalk*, repo : Repository) : LibC::Int
  fun revwalk_reset = git_revwalk_reset(walker : Revwalk) : LibC::Int
  fun revwalk_push = git_revwalk_push(walk : Revwalk, id : Oid*) : LibC::Int
  fun revwalk_push_glob = git_revwalk_push_glob(walk : Revwalk, glob : LibC::Char*) : LibC::Int
  fun revwalk_push_head = git_revwalk_push_head(walk : Revwalk) : LibC::Int
  fun revwalk_hide = git_revwalk_hide(walk : Revwalk, commit_id : Oid*) : LibC::Int
  fun revwalk_hide_glob = git_revwalk_hide_glob(walk : Revwalk, glob : LibC::Char*) : LibC::Int
  fun revwalk_hide_head = git_revwalk_hide_head(walk : Revwalk) : LibC::Int
  fun revwalk_push_ref = git_revwalk_push_ref(walk : Revwalk, refname : LibC::Char*) : LibC::Int
  fun revwalk_hide_ref = git_revwalk_hide_ref(walk : Revwalk, refname : LibC::Char*) : LibC::Int
  fun revwalk_next = git_revwalk_next(out : Oid*, walk : Revwalk) : LibC::Int
  fun revwalk_sorting = git_revwalk_sorting(walk : Revwalk, sort_mode : LibC::UInt) : LibC::Int
  fun revwalk_pathspec = git_revwalk_pathspec(walk : Revwalk, pathspec : Pathspec) : LibC::Int
  fun revwalk_push_range = git_revwalk_push_range(walk : Revwalk, range : LibC::Char*) : LibC::Int
  fun revwalk_simplify_first_parent = git_revwalk_simplify_first_parent(walk : Revwalk) : LibC::Int
  fun revwalk_free = git_revwalk_free(walk : Revwalk)
  fun revwalk_repository = git_revwalk_repository(walk : Revwalk) : Repository
  fun revwalk_add_hide_cb = git_revwalk_add_hide_cb(walk : Revwalk, hide_cb : RevwalkHideCb, payload : Void*) : LibC::Int

  fun libgit2_init = git_libgit2_init : LibC::Int
  fun libgit2_shutdown = git_libgit2_shutdown : LibC::Int

  fun object_lookup = git_object_lookup(object : Object*, repo : Repository, id : Oid*, type : ObjectType) : LibC::Int
  fun object_id = git_object_id(obj : Object) : Oid*
  fun object_type = git_object_type(obj    : Object) : ObjectType
  fun object_peel = git_object_peel(peeled : Object*, object : Object, target_type : ObjectType) : LibC::Int
  fun object_free = git_object_free(object : Object)

  fun tag_lookup = git_tag_lookup(out_tag : Tag*, repo : Repository, id : Oid*) : LibC::Int
  fun tag_free = git_tag_free(tag : Tag)
  fun tag_id = git_tag_id(tag : Tag) : Oid*
  fun tag_name = git_tag_name(tag : Tag) : LibC::Char*
  fun tag_message = git_tag_message(tag : Tag) : LibC::Char*
  fun tag_target_id = git_tag_target_id(tag : Tag) : Oid*
  fun tag_create = git_tag_create(oid : Oid*, repo : Repository, tag_name : LibC::Char*, target : Object, tagger : Signature*, message : LibC::Char*, force : LibC::Int) : LibC::Int
  fun tag_create_lightweight = git_tag_create_lightweight(oid : Oid*, repo : Repository, tag_name : LibC::Char*, target : Object, force : LibC::Int) : LibC::Int
  fun tag_delete = git_tag_delete(repo : Repository, tag_name : LibC::Char*) : LibC::Int
  fun tag_list = git_tag_list(array : Strarray*, repo : Repository) : LibC::Int
  fun tag_name_is_valid = git_tag_name_is_valid(valid : LibC::Int*, name : LibC::Char*) : LibC::Int

  fun merge = git_merge(repo : Repository, their_heads : AnnotatedCommit*, their_heads_len : LibC::SizeT, merge_opts : MergeOptions*, checkout_opts : CheckoutOptions*) : LibC::Int

  struct CherrypickOptions
    version       : LibC::UInt
    mainline      : LibC::UInt
    merge_opts    : MergeOptions
    checkout_opts : CheckoutOptions
  end

  fun cherrypick_options_init = git_cherrypick_options_init(opts : CherrypickOptions*, version : LibC::UInt) : LibC::Int
  fun cherrypick = git_cherrypick(repo : Repository, commit : Commit, opts : CherrypickOptions*) : LibC::Int
  fun cherrypick_commit = git_cherrypick_commit(out_idx : Index*, repo : Repository, cherrypick_commit : Commit, our_commit : Commit, mainline : LibC::UInt, merge_options : MergeOptions*) : LibC::Int

  struct RevertOptions
    version       : LibC::UInt
    mainline      : LibC::UInt
    merge_opts    : MergeOptions
    checkout_opts : CheckoutOptions
  end

  fun revert_options_init = git_revert_options_init(opts : RevertOptions*, version : LibC::UInt) : LibC::Int
  fun revert = git_revert(repo : Repository, commit : Commit, given_opts : RevertOptions*) : LibC::Int
  fun revert_commit = git_revert_commit(out_idx : Index*, repo : Repository, revert_commit : Commit, our_commit : Commit, mainline : LibC::UInt, merge_options : MergeOptions*) : LibC::Int

  fun remote_lookup = git_remote_lookup(out_remote : Remote*, repo : Repository, name : LibC::Char*) : LibC::Int
  fun remote_create = git_remote_create(out_remote : Remote*, repo : Repository, name : LibC::Char*, url : LibC::Char*) : LibC::Int
  fun remote_create_anonymous = git_remote_create_anonymous(out_remote : Remote*, repo : Repository, url : LibC::Char*) : LibC::Int
  fun remote_free = git_remote_free(remote : Remote)
  fun remote_name = git_remote_name(remote : Remote) : LibC::Char*
  fun remote_url = git_remote_url(remote : Remote) : LibC::Char*
  fun remote_list = git_remote_list(out_array : Strarray*, repo : Repository) : LibC::Int
  fun remote_fetch = git_remote_fetch(remote : Remote, refspecs : Strarray*, opts : FetchOptions*, reflog_message : LibC::Char*) : LibC::Int
  fun remote_push = git_remote_push(remote : Remote, refspecs : Strarray*, opts : PushOptions*) : LibC::Int
  fun remote_prune = git_remote_prune(remote : Remote, callbacks : RemoteCallbacks*) : LibC::Int
  fun remote_delete = git_remote_delete(repo : Repository, name : LibC::Char*) : LibC::Int

  fun transaction_new = git_transaction_new(out_tx : Transaction*, repo : Repository) : LibC::Int
  fun transaction_lock_ref = git_transaction_lock_ref(tx : Transaction, refname : LibC::Char*) : LibC::Int
  fun transaction_set_target = git_transaction_set_target(tx : Transaction, refname : LibC::Char*, target : Oid*, sig : Signature*, msg : LibC::Char*) : LibC::Int
  fun transaction_set_symbolic_target = git_transaction_set_symbolic_target(tx : Transaction, refname : LibC::Char*, target : LibC::Char*, sig : Signature*, msg : LibC::Char*) : LibC::Int
  fun transaction_remove = git_transaction_remove(tx : Transaction, refname : LibC::Char*) : LibC::Int
  fun transaction_commit = git_transaction_commit(tx : Transaction) : LibC::Int
  fun transaction_free = git_transaction_free(tx : Transaction)
end
