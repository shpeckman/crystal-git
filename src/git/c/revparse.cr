# src/git/c/revparse.cr
@[Link("git2")]
lib LibGit2
  # ============================================================================
  # REVPARSE (git2/revparse.h)
  # ============================================================================

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
  fun revparse_ext = git_revparse_ext(object_out : Object**, reference_out : Reference**, repo : Repository, spec : LibC::Char*) : LibC::Int
  fun revparse = git_revparse(revspec : Revspec*, repo : Repository, spec : LibC::Char*) : LibC::Int
end
