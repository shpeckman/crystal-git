# src/git/c/submodule.cr
@[Link("git2")]
lib LibGit2
  # ============================================================================
  # SUBMODULES (git2/submodule.h)
  # ============================================================================

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
  fun submodule_open = git_submodule_open(out_repo : Repository*, submodule : Submodule) : LibC::Int
  fun submodule_reload = git_submodule_reload(submodule : Submodule, force : LibC::Int) : LibC::Int

  fun submodule_status = git_submodule_status(out_status : LibC::UInt*, repo : Repository, name : LibC::Char*, ignore : SubmoduleIgnoreType) : LibC::Int
  fun submodule_location = git_submodule_location(out_location_status : LibC::UInt*, submodule : Submodule) : LibC::Int
end
