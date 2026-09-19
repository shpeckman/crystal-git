# src/git/c/checkout.cr
@[Link("git2")]
lib LibGit2
  # ============================================================================
  # CHECKOUT (git2/checkout.h)
  # ============================================================================

  enum CheckoutStrategy
    SAFE                         =          0
    FORCE                        =          2
    RECREATE_MISSING             =          4
    ALLOW_CONFLICTS              =         16
    REMOVE_UNTRACKED             =         32
    REMOVE_IGNORED               =         64
    UPDATE_ONLY                  =        128
    DONT_UPDATE_INDEX            =        256
    NO_REFRESH                   =        512
    SKIP_UNMERGED                =       1024
    USE_OURS                     =       2048
    USE_THEIRS                   =       4096
    DISABLE_PATHSPEC_MATCH       =       8192
    UPDATE_SUBMODULES            =      65536
    UPDATE_SUBMODULES_IF_CHANGED =     131072
    SKIP_LOCKED_DIRECTORIES      =     262144
    DONT_OVERWRITE_IGNORED       =     524288
    CONFLICT_STYLE_MERGE         =    1048576
    CONFLICT_STYLE_DIFF3         =    2097152
    DONT_REMOVE_EXISTING         =    4194304
    DONT_WRITE_INDEX             =    8388608
    DRY_RUN                      =   16777216
    CONFLICT_STYLE_ZDIFF3        =   33554432
    NONE                         = 1073741824
  end

  enum CheckoutNotify
    NONE      =     0
    CONFLICT  =     1
    DIRTY     =     2
    UPDATED   =     4
    UNTRACKED =     8
    IGNORED   =    16
    ALL       = 65535
  end

  struct CheckoutOptions
    version           : LibC::UInt
    checkout_strategy : LibC::UInt32
    disable_filters   : LibC::Int
    dir_mode          : LibC::UInt
    file_mode         : LibC::UInt
    file_open_flags   : LibC::Int
    notify_flags      : LibC::UInt
    notify_cb         : Void*
    notify_payload    : Void*
    progress_cb       : Void*
    progress_payload  : Void*
    paths             : Strarray
    baseline          : Tree
    baseline_index    : Index
    target_directory  : LibC::Char*
    ancestor_label    : LibC::Char*
    our_label         : LibC::Char*
    their_label       : LibC::Char*
    perfdata_cb       : Void*
    perfdata_payload  : Void*
  end

  fun checkout_options_init = git_checkout_options_init(opts : CheckoutOptions*, version : LibC::UInt) : LibC::Int
  fun checkout_head = git_checkout_head(repo : Repository, opts : CheckoutOptions*) : LibC::Int
  fun checkout_index = git_checkout_index(repo : Repository, index : Index, opts : CheckoutOptions*) : LibC::Int
  fun checkout_tree = git_checkout_tree(repo : Repository, treeish : Object, opts : CheckoutOptions*) : LibC::Int
end
