# src/git/c/worktree.cr
@[Link("git2")]
lib LibGit2
  # ============================================================================
  # WORKTREE (git2/worktree.h)
  # ============================================================================

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
    flags   : LibC::UInt32
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
end
