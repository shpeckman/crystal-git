# src/git/libgit2.cr
require "./c/types"
require "./c/errors"
require "./c/buffer"
require "./c/strarray"
require "./c/oid"
require "./c/credential"
require "./c/repository"
require "./c/commit"
require "./c/tree"
require "./c/blob"
require "./c/branch"
require "./c/refs"
require "./c/index"
require "./c/diff"
require "./c/status"
require "./c/checkout"
require "./c/proxy"
require "./c/remote"
require "./c/clone"
require "./c/config"
require "./c/submodule"
require "./c/signature"
require "./c/merge"
require "./c/rebase"
require "./c/stash"
require "./c/reset"
require "./c/odb"
require "./c/reflog"
require "./c/blame"
require "./c/worktree"
require "./c/patch"
require "./c/revparse"

@[Link("git2")]
lib LibGit2
  # ============================================================================
  # GLOBAL (git2/global.h)
  # ============================================================================

  fun libgit2_init = git_libgit2_init : LibC::Int
  fun libgit2_shutdown = git_libgit2_shutdown : LibC::Int
end
