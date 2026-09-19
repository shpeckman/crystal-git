# src/git/c/status.cr
@[Link("git2")]
lib LibGit2
  # ============================================================================
  # STATUS (git2/status.h)
  # ============================================================================

  enum StatusType : UInt32
    CURRENT          =     0
    INDEX_NEW        =     1
    INDEX_MODIFIED   =     2
    INDEX_DELETED    =     4
    INDEX_RENAMED    =     8
    INDEX_TYPECHANGE =    16
    WT_NEW           =   128
    WT_MODIFIED      =   256
    WT_DELETED       =   512
    WT_TYPECHANGE    =  1024
    WT_RENAMED       =  2048
    WT_UNREADABLE    =  4096
    IGNORED          = 16384
    CONFLICTED       = 32768
  end

  enum StatusShow
    INDEX_AND_WORKDIR = 0
    INDEX_ONLY        = 1
    WORKDIR_ONLY      = 2
  end

  enum StatusOpt : UInt32
    INCLUDE_UNTRACKED               =     1
    INCLUDE_IGNORED                 =     2
    INCLUDE_UNMODIFIED              =     4
    EXCLUDE_SUBMODULES              =     8
    RECURSE_UNTRACKED_DIRS          =    16
    DISABLE_PATHSPEC_MATCH          =    32
    RECURSE_IGNORED_DIRS            =    64
    RENAMES_HEAD_TO_INDEX           =   128
    RENAMES_INDEX_TO_WORKDIR        =   256
    SORT_CASE_SENSITIVELY           =   512
    SORT_CASE_INSENSITIVELY         =  1024
    RENAMES_FROM_REWRITES           =  2048
    NO_REFRESH                      =  4096
    UPDATE_INDEX                    =  8192
    INCLUDE_UNREADABLE              = 16384
    INCLUDE_UNREADABLE_AS_UNTRACKED = 32768
  end

  struct StatusOptions
    version          : LibC::UInt
    show             : StatusShow
    flags            : UInt32
    pathspec         : Strarray
    baseline         : Tree
    rename_threshold : UInt16
  end

  struct StatusEntry
    status           : StatusType
    head_to_index    : DiffDelta*
    index_to_workdir : DiffDelta*
  end

  alias StatusCb = (LibC::Char*, LibC::UInt, Void* -> LibC::Int)

  fun status_options_init = git_status_options_init(opts : StatusOptions*, version : LibC::UInt) : LibC::Int
  fun status_foreach = git_status_foreach(repo : Repository, callback : StatusCb, payload : Void*) : LibC::Int
  fun status_foreach_ext = git_status_foreach_ext(repo : Repository, opts : StatusOptions*, callback : StatusCb, payload : Void*) : LibC::Int
  fun status_file = git_status_file(status_flags : LibC::UInt*, repo : Repository, path : LibC::Char*) : LibC::Int
  fun status_list_new = git_status_list_new(out_list : StatusList*, repo : Repository, opts : StatusOptions*) : LibC::Int
  fun status_list_entrycount = git_status_list_entrycount(statuslist : StatusList) : LibC::SizeT
  fun status_byindex = git_status_byindex(statuslist : StatusList, idx : LibC::SizeT) : StatusEntry*
  fun status_list_free = git_status_list_free(statuslist : StatusList)
  fun status_should_ignore = git_status_should_ignore(ignored : LibC::Int*, repo : Repository, path : LibC::Char*) : LibC::Int
end
