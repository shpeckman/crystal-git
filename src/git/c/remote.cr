# src/git/c/remote.cr
@[Link("git2")]
lib LibGit2
  # ============================================================================
  # REMOTE (git2/remote.h)
  # ============================================================================

  enum RemoteRedirect
    NONE    = 1
    INITIAL = 2
    ALL     = 4
  end

  enum FetchPrune
    UNSPECIFIED = 0
    PRUNE       = 1
    NO_PRUNE    = 2
  end

  enum RemoteAutotagOption
    UNSPECIFIED = 0
    AUTO        = 1
    NONE        = 2
    ALL         = 3
  end

  alias RemoteSidebandProgressCb = (LibC::Char*, LibC::Int, Void* -> LibC::Int)
  alias RemoteCompletionCb = (LibC::Int, Void* -> LibC::Int)
  alias TransferProgressCb = (Void*, Void* -> LibC::Int)
  alias UpdateTipsCb = (LibC::Char*, Oid*, Oid*, Void* -> LibC::Int)
  alias PackbuilderProgressCb = (LibC::Int, UInt32, UInt32, Void* -> LibC::Int)
  alias PushTransferProgressCb = (UInt32, UInt32, LibC::SizeT, Void* -> LibC::Int)
  alias PushUpdateReferenceCb = (LibC::Char*, LibC::Char*, Void* -> LibC::Int)
  alias PushNegotiationCb = (Void*, LibC::SizeT, Void* -> LibC::Int)
  alias TransportCb = (Transport*, Remote, Void* -> LibC::Int)
  alias RemoteReadyCb = (Remote, LibC::Int, Void* -> LibC::Int)
  alias ResolveUrlCb = (Buf*, LibC::Char*, LibC::Int, Void* -> LibC::Int)

  struct RemoteCallbacks
    version                : LibC::UInt
    sideband_progress      : RemoteSidebandProgressCb
    completion             : RemoteCompletionCb
    credentials            : CredentialAcquireCb
    certificate_check      : TransportCertificateCheckCb
    transfer_progress      : TransferProgressCb
    update_tips            : UpdateTipsCb
    pack_progress          : PackbuilderProgressCb
    push_transfer_progress : PushTransferProgressCb
    push_update_reference  : PushUpdateReferenceCb
    push_negotiation       : PushNegotiationCb
    transport              : TransportCb
    remote_ready           : RemoteReadyCb
    payload                : Void*
    resolve_url            : ResolveUrlCb
    update_refs            : Void*
  end

  struct FetchOptions
    version          : LibC::Int
    callbacks        : RemoteCallbacks
    prune            : FetchPrune
    update_fetchhead : LibC::UInt
    download_tags    : RemoteAutotagOption
    proxy_opts       : ProxyOptions
    depth            : LibC::Int
    follow_redirects : RemoteRedirect
    custom_headers   : Strarray
  end

  struct PushOptions
    version             : LibC::UInt
    pb_parallelism      : LibC::UInt
    callbacks           : RemoteCallbacks
    proxy_opts          : ProxyOptions
    follow_redirects    : RemoteRedirect
    custom_headers      : Strarray
    remote_push_options : Strarray
  end

  struct RemoteConnectOptions
    version          : LibC::UInt
    callbacks        : RemoteCallbacks
    proxy_opts       : ProxyOptions
    follow_redirects : RemoteRedirect
    custom_headers   : Strarray
  end

  fun remote_init_callbacks = git_remote_init_callbacks(opts : RemoteCallbacks*, version : LibC::UInt) : LibC::Int
  fun fetch_options_init = git_fetch_options_init(opts : FetchOptions*, version : LibC::UInt) : LibC::Int
  fun push_options_init = git_push_options_init(opts : PushOptions*, version : LibC::UInt) : LibC::Int
  fun remote_connect_options_init = git_remote_connect_options_init(opts : RemoteConnectOptions*, version : LibC::UInt) : LibC::Int
end
