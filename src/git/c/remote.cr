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

  struct RemoteCallbacks
    version                : LibC::UInt
    sideband_progress      : Void*
    completion             : Void*
    credentials            : Void*
    certificate_check      : Void*
    transfer_progress      : Void*
    update_tips            : Void*
    pack_progress          : Void*
    push_transfer_progress : Void*
    push_update_reference  : Void*
    push_negotiation       : Void*
    transport              : Void*
    remote_ready           : Void*
    payload                : Void*
    resolve_url            : Void*
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
