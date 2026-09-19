# src/git/c/stash.cr
@[Link("git2")]
lib LibGit2
  # ============================================================================
  # STASH (git2/stash.h)
  # ============================================================================

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
end
