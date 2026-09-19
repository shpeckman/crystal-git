# src/git/c/clone.cr
@[Link("git2")]
lib LibGit2
  # ============================================================================
  # CLONE (git2/clone.h)
  # ============================================================================

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
end
