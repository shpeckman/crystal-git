# src/git/c/diff.cr
@[Link("git2")]
lib LibGit2
  # ============================================================================
  # DIFF (git2/diff.h)
  # ============================================================================

  enum DiffOption : UInt32
    NORMAL                          =          0
    REVERSE                         =          1
    INCLUDE_IGNORED                 =          2
    RECURSE_IGNORED_DIRS            =          4
    INCLUDE_UNTRACKED               =          8
    RECURSE_UNTRACKED_DIRS          =         16
    INCLUDE_UNMODIFIED              =         32
    INCLUDE_TYPECHANGE              =         64
    INCLUDE_TYPECHANGE_TREES        =        128
    IGNORE_FILEMODE                 =        256
    IGNORE_SUBMODULES               =        512
    IGNORE_CASE                     =       1024
    INCLUDE_CASECHANGE              =       2048
    DISABLE_PATHSPEC_MATCH          =       4096
    SKIP_BINARY_CHECK               =       8192
    ENABLE_FAST_UNTRACKED_DIRS      =      16384
    UPDATE_INDEX                    =      32768
    INCLUDE_UNREADABLE              =      65536
    INCLUDE_UNREADABLE_AS_UNTRACKED =     131072
    INDENT_HEURISTIC                =     262144
    IGNORE_BLANK_LINES              =     524288
    FORCE_TEXT                      =    1048576
    FORCE_BINARY                    =    2097152
    IGNORE_WHITESPACE               =    4194304
    IGNORE_WHITESPACE_CHANGE        =    8388608
    IGNORE_WHITESPACE_EOL           =   16777216
    SHOW_UNTRACKED_CONTENT          =   33554432
    SHOW_UNMODIFIED                 =   67108864
    PATIENCE                        =  268435456
    MINIMAL                         =  536870912
    SHOW_BINARY                     = 1073741824
  end

  enum DiffFlag : UInt32
    BINARY     =  1
    NOT_BINARY =  2
    VALID_ID   =  4
    EXISTS     =  8
    VALID_SIZE = 16
  end

  enum DeltaType
    UNMODIFIED =  0
    ADDED      =  1
    DELETED    =  2
    MODIFIED   =  3
    RENAMED    =  4
    COPIED     =  5
    IGNORED    =  6
    UNTRACKED  =  7
    TYPECHANGE =  8
    UNREADABLE =  9
    CONFLICTED = 10
  end

  struct DiffFile
    id        : Oid
    path      : LibC::Char*
    size      : UInt64
    flags     : UInt32
    mode      : UInt16
    id_abbrev : UInt16
  end

  struct DiffDelta
    status     : DeltaType
    flags      : UInt32
    similarity : UInt16
    nfiles     : UInt16
    old_file   : DiffFile
    new_file   : DiffFile
  end

  alias DiffNotifyCb = (Diff, DiffDelta*, LibC::Char*, Void* -> LibC::Int)
  alias DiffProgressCb = (Diff, LibC::Char*, LibC::Char*, Void* -> LibC::Int)

  struct DiffOptions
    version           : LibC::UInt
    flags             : UInt32
    ignore_submodules : SubmoduleIgnoreType
    pathspec          : Strarray
    notify_cb         : DiffNotifyCb
    progress_cb       : DiffProgressCb
    payload           : Void*
    context_lines     : UInt32
    interhunk_lines   : UInt32
    oid_type          : OidType
    id_abbrev         : UInt16
    max_size          : Int64
    old_prefix        : LibC::Char*
    new_prefix        : LibC::Char*
  end

  struct DiffHunk
    old_start  : LibC::Int
    old_lines  : LibC::Int
    new_start  : LibC::Int
    new_lines  : LibC::Int
    header_len : LibC::SizeT
    header     : StaticArray(LibC::Char, 128)
  end

  struct DiffLine
    origin         : LibC::Char
    old_lineno     : LibC::Int
    new_lineno     : LibC::Int
    num_lines      : LibC::Int
    content_len    : LibC::SizeT
    content_offset : Int64
    content        : LibC::Char*
  end

  enum DiffFindOption : UInt32
    BY_CONFIG                       =     0
    RENAMES                         =     1
    RENAMES_FROM_REWRITES           =     2
    COPIES                          =     4
    COPIES_FROM_UNMODIFIED          =     8
    REWRITES                        =    16
    BREAK_REWRITES                  =    32
    FIND_AND_BREAK_REWRITES         =    48
    FOR_UNTRACKED                   =    64
    ALL                             =   255
    IGNORE_LEADING_WHITESPACE       =     0
    IGNORE_WHITESPACE               =  4096
    DONT_IGNORE_WHITESPACE          =  8192
    EXACT_MATCH_ONLY                = 16384
    BREAK_REWRITES_FOR_RENAMES_ONLY = 32768
    REMOVE_UNMODIFIED               = 65536
  end

  struct DiffFindOptions
    version                       : LibC::UInt
    flags                         : UInt32
    rename_threshold              : UInt16
    rename_from_rewrite_threshold : UInt16
    copy_threshold                : UInt16
    break_rewrite_threshold       : UInt16
    rename_limit                  : LibC::SizeT
    metric                        : Void*
  end

  enum DiffFormat
    PATCH        = 1
    PATCH_HEADER = 2
    RAW          = 3
    NAME_ONLY    = 4
    NAME_STATUS  = 5
    PATCH_ID     = 6
  end

  alias DiffFileCb = (DiffDelta*, LibC::Float, Void* -> LibC::Int)
  alias DiffBinaryCb = (DiffDelta*, Void*, Void* -> LibC::Int)
  alias DiffHunkCb = (DiffDelta*, DiffHunk*, Void* -> LibC::Int)
  alias DiffLineCb = (DiffDelta*, DiffHunk*, DiffLine*, Void* -> LibC::Int)

  fun diff_options_init = git_diff_options_init(opts : DiffOptions*, version : LibC::UInt) : LibC::Int
  fun diff_find_options_init = git_diff_find_options_init(opts : DiffFindOptions*, version : LibC::UInt) : LibC::Int
  fun diff_free = git_diff_free(diff : Diff)
  fun diff_tree_to_tree = git_diff_tree_to_tree(diff : Diff*, repo : Repository, old_tree : Tree, new_tree : Tree, opts : DiffOptions*) : LibC::Int
  fun diff_tree_to_index = git_diff_tree_to_index(diff : Diff*, repo : Repository, old_tree : Tree, index : Index, opts : DiffOptions*) : LibC::Int
  fun diff_index_to_workdir = git_diff_index_to_workdir(diff : Diff*, repo : Repository, index : Index, opts : DiffOptions*) : LibC::Int
  fun diff_tree_to_workdir = git_diff_tree_to_workdir(diff : Diff*, repo : Repository, old_tree : Tree, opts : DiffOptions*) : LibC::Int
  fun diff_tree_to_workdir_with_index = git_diff_tree_to_workdir_with_index(diff : Diff*, repo : Repository, old_tree : Tree, opts : DiffOptions*) : LibC::Int
  fun diff_index_to_index = git_diff_index_to_index(diff : Diff*, repo : Repository, old_index : Index, new_index : Index, opts : DiffOptions*) : LibC::Int
  fun diff_merge = git_diff_merge(onto : Diff, from : Diff) : LibC::Int
  fun diff_find_similar = git_diff_find_similar(diff : Diff, options : DiffFindOptions*) : LibC::Int
  fun diff_num_deltas = git_diff_num_deltas(diff : Diff) : LibC::SizeT
  fun diff_num_deltas_of_type = git_diff_num_deltas_of_type(diff : Diff, type : DeltaType) : LibC::SizeT
  fun diff_get_delta = git_diff_get_delta(diff : Diff, idx : LibC::SizeT) : DiffDelta*
  fun diff_is_sorted_icase = git_diff_is_sorted_icase(diff : Diff) : LibC::Int
  fun diff_foreach = git_diff_foreach(diff : Diff, file_cb : DiffFileCb, binary_cb : DiffBinaryCb, hunk_cb : DiffHunkCb, line_cb : DiffLineCb, payload : Void*) : LibC::Int
  fun diff_status_char = git_diff_status_char(status : DeltaType) : LibC::Char
  fun diff_print = git_diff_print(diff : Diff, format : DiffFormat, print_cb : DiffLineCb, payload : Void*) : LibC::Int
  fun diff_to_buf = git_diff_to_buf(out_buf : Buf*, diff : Diff, format : DiffFormat) : LibC::Int
end
