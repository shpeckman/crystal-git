# src/git/c/merge.cr
@[Link("git2")]
lib LibGit2
  # ============================================================================
  # MERGE (git2/merge.h)
  # ============================================================================

  enum MergeFlag
    FIND_RENAMES     =  1
    FAIL_ON_CONFLICT =  2
    SKIP_REUC        =  4
    NO_RECURSIVE     =  8
    VIRTUAL_BASE     = 16
  end

  enum MergeFileFavor
    NORMAL = 0
    OURS   = 1
    THEIRS = 2
    UNION  = 3
  end

  enum MergeFileFlag
    DEFAULT                  =   0
    STYLE_MERGE              =   1
    STYLE_DIFF3              =   2
    SIMPLIFY_ALNUM           =   4
    IGNORE_WHITESPACE        =   8
    IGNORE_WHITESPACE_CHANGE =  16
    IGNORE_WHITESPACE_EOL    =  32
    DIFF_PATIENCE            =  64
    DIFF_MINIMAL             = 128
    STYLE_ZDIFF3             = 256
    ACCEPT_CONFLICTS         = 512
  end

  struct MergeFileInput
    version : LibC::UInt
    ptr     : LibC::Char*
    size    : LibC::SizeT
    path    : LibC::Char*
    mode    : LibC::UInt
  end

  struct MergeFileOptions
    version        : LibC::UInt
    ancestor_label : LibC::Char*
    our_label      : LibC::Char*
    their_label    : LibC::Char*
    favor          : MergeFileFavor
    flags          : LibC::UInt32
    marker_size    : LibC::UShort
  end

  struct MergeFileResult
    automergeable : LibC::UInt
    path          : LibC::Char*
    mode          : LibC::UInt
    ptr           : LibC::Char*
    len           : LibC::SizeT
  end

  enum MergeAnalysis
    NONE        = 0
    NORMAL      = 1
    UP_TO_DATE  = 2
    FASTFORWARD = 4
    UNBORN      = 8
  end

  enum MergePreference
    NONE             = 0
    NO_FASTFORWARD   = 1
    FASTFORWARD_ONLY = 2
  end

  fun merge_file_input_init = git_merge_file_input_init(opts : MergeFileInput*, version : LibC::UInt) : LibC::Int
  fun merge_file_options_init = git_merge_file_options_init(opts : MergeFileOptions*, version : LibC::UInt) : LibC::Int

  fun merge_analysis = git_merge_analysis(analysis_out : MergeAnalysis*, preference_out : MergePreference*, repo : Repository, their_heads : AnnotatedCommit**, their_heads_len : LibC::SizeT) : LibC::Int
  fun merge_analysis_for_ref = git_merge_analysis_for_ref(analysis_out : MergeAnalysis*, preference_out : MergePreference*, repo : Repository, our_ref : Reference, their_heads : AnnotatedCommit**, their_heads_len : LibC::SizeT) : LibC::Int

  fun merge_base = git_merge_base(out_oid : Oid*, repo : Repository, one : Oid*, two : Oid*) : LibC::Int
  fun merge_bases = git_merge_bases(out_array : Void*, repo : Repository, one : Oid*, two : Oid*) : LibC::Int
  fun merge_base_many = git_merge_base_many(out_oid : Oid*, repo : Repository, length : LibC::SizeT, input_array : Oid*) : LibC::Int
  fun merge_bases_many = git_merge_bases_many(out_array : Void*, repo : Repository, length : LibC::SizeT, input_array : Oid*) : LibC::Int
  fun merge_base_octopus = git_merge_base_octopus(out_oid : Oid*, repo : Repository, length : LibC::SizeT, input_array : Oid*) : LibC::Int

  fun merge_file = git_merge_file(out_res : MergeFileResult*, ancestor : MergeFileInput*, ours : MergeFileInput*, theirs : MergeFileInput*, opts : MergeFileOptions*) : LibC::Int
  fun merge_file_from_index = git_merge_file_from_index(out_res : MergeFileResult*, repo : Repository, ancestor : IndexEntry*, ours : IndexEntry*, theirs : IndexEntry*, opts : MergeFileOptions*) : LibC::Int
  fun merge_file_result_free = git_merge_file_result_free(result : MergeFileResult*)

  fun merge_trees = git_merge_trees(out_idx : Index*, repo : Repository, ancestor_tree : Tree, our_tree : Tree, their_tree : Tree, opts : MergeOptions*) : LibC::Int
  fun merge_commits = git_merge_commits(out_idx : Index*, repo : Repository, our_commit : Commit, their_commit : Commit, opts : MergeOptions*) : LibC::Int
end
