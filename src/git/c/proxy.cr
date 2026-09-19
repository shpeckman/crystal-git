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
end
