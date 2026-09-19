# src/git/c/errors.cr
@[Link("git2")]
lib LibGit2
  # git2/errors.h
  enum ErrorCode
    OK              =   0
    ERROR           =  -1
    ENOTFOUND       =  -3
    EEXISTS         =  -4
    EAMBIGUOUS      =  -5
    EBUFS           =  -6
    EUSER           =  -7
    EBAREREPO       =  -8
    EUNBORNBRANCH   =  -9
    EUNMERGED       = -10
    ENONFASTFORWARD = -11
    EINVALIDSPEC    = -12
    ECONFLICT       = -13
    ELOCKED         = -14
    EMODIFIED       = -15
    EAUTH           = -16
    ECERTIFICATE    = -17
    EAPPLIED        = -18
    EPEEL           = -19
    EEOF            = -20
    EINVALID        = -21
    EUNCOMMITTED    = -22
    EDIRECTORY      = -23
    EMERGECONFLICT  = -24
    PASSTHROUGH     = -30
    ITEROVER        = -31
    RETRY           = -32
    EMISMATCH       = -33
    EINDEXDIRTY     = -34
    EAPPLYFAIL      = -35
    EOWNER          = -36
    TIMEOUT         = -37
    EUNCHANGED      = -38
    ENOTSUPPORTED   = -39
    EREADONLY       = -40
  end

  enum ErrorType
    NONE       = 0
    NOMEMORY
    OS
    INVALID
    REFERENCE
    ZLIB
    REPOSITORY
    CONFIG
    REGEX
    ODB
    INDEX
    OBJECT
    NET
    TAG
    TREE
    INDEXER
    SSL
    SUBMODULE
    THREAD
    STASH
    CHECKOUT
    FETCHHEAD
    MERGE
    SSH
    FILTER
    REVERT
    CALLBACK
    CHERRYPICK
    DESCRIBE
    REBASE
    FILESYSTEM
    PATCH
    WORKTREE
    SHA
    HTTP
    INTERNAL
    GRAFTS
  end

  struct Error
    message : LibC::Char*
    klass   : LibC::Int
  end

  fun err_last = git_error_last : Error*
  fun err_clear = git_error_clear
  fun err_set_str = git_error_set_str(error_class : LibC::Int, string : LibC::Char*) : LibC::Int
  fun err_set_oom = git_error_set_oom
end
