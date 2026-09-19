# src/git/c/reset.cr
@[Link("git2")]
lib LibGit2
  # ============================================================================
  # RESET (git2/reset.h)
  # ============================================================================

  fun reset_default = git_reset_default(repo : Repository, target : Object, pathspecs : Strarray*) : LibC::Int
  fun reset_from_annotated = git_reset_from_annotated(repo : Repository, target : AnnotatedCommit, reset_type : ResetType, checkout_opts : CheckoutOptions*) : LibC::Int
end
