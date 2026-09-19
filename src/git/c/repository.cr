# src/git/c/repository.cr
@[Link("git2")]
lib LibGit2
  # git2/repository.h
  enum RepositoryOpenFlag
    NO_SEARCH = 1
    CROSS_FS = 2
    BARE = 4
    NO_DOTGIT = 8
    FROM_ENV = 16
  end

  enum RepositoryInitFlag
    BARE = 1
    NO_REINIT = 2
    MKDIR = 8
    MKPATH = 16
    EXTERNAL_TEMPLATE = 32
    RELATIVE_GITLINK = 64
  end

  enum RepositoryInitMode
    SHARED_UMASK = 0
    SHARED_GROUP = 1533 # 0002775 octal
    SHARED_ALL = 1535   # 0002777 octal
  end

  struct RepositoryInitOptions
    version : LibC::UInt
    flags : LibC::UInt32
    mode : LibC::UInt32
    workdir_path : LibC::Char*
    description : LibC::Char*
    template_path : LibC::Char*
    initial_head : LibC::Char*
    origin_url : LibC::Char*
    oid_type : OidType
    refdb_type : RefdbType
  end

  enum RepositoryItem
    GITDIR = 0
    WORKDIR = 1
    COMMONDIR = 2
    INDEX = 3
    OBJECTS = 4
    REFS = 5
    PACKED_REFS = 6
    REMOTES = 7
    CONFIG = 8
    INFO = 9
    HOOKS = 10
    LOGS = 11
    MODULES = 12
    WORKTREES = 13
    WORKTREE_CONFIG = 14
    _LAST = 15
  end

  enum RepositoryState
    NONE = 0
    MERGE = 1
    REVERT = 2
    REVERT_SEQUENCE = 3
    CHERRYPICK = 4
    CHERRYPICK_SEQUENCE = 5
    BISECT = 6
    REBASE = 7
    REBASE_INTERACTIVE = 8
    REBASE_MERGE = 9
    APPLY_MAILBOX = 10
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
  fun repository_free = git_repository_free(repo : Repository)
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
end

