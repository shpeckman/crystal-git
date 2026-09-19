# src/git/c/proxy.cr
@[Link("git2")]
lib LibGit2
  # ============================================================================
  # PROXY (git2/proxy.h)
  # ============================================================================

  enum ProxyType
    NONE      = 0
    AUTO      = 1
    SPECIFIED = 2
  end

  struct ProxyOptions
    version           : LibC::UInt
    type              : ProxyType
    url               : LibC::Char*
    credentials       : Void*       # git_credential_acquire_cb
    certificate_check : Void* # git_transport_certificate_check_cb
    payload           : Void*
  end

  fun proxy_options_init = git_proxy_options_init(opts : ProxyOptions*, version : LibC::UInt) : LibC::Int
end
