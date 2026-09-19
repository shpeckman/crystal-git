# src/git/c/blame.cr
@[Link("git2")]
lib LibGit2
  # ============================================================================
  # BLAME (git2/blame.h)
  # ============================================================================

  enum BlameFlag : UInt32
    NORMAL                          =  0
    TRACK_COPIES_SAME_FILE          =  1
    TRACK_COPIES_SAME_COMMIT_MOVES  =  2
    TRACK_COPIES_SAME_COMMIT_COPIES =  4
    TRACK_COPIES_ANY_COMMIT_COPIES  =  8
    FIRST_PARENT                    = 16
    USE_MAILMAP                     = 32
    IGNORE_WHITESPACE               = 64
  end

  struct BlameOptions
    version              : LibC::UInt
    flags                : UInt32
    min_match_characters : UInt16
    newest_commit        : Oid
    oldest_commit        : Oid
    min_line             : LibC::SizeT
    max_line             : LibC::SizeT
  end

  struct BlameHunk
    lines_in_hunk           : LibC::SizeT
    final_commit_id         : Oid
    final_start_line_number : LibC::SizeT
    final_signature         : Signature*
    final_committer         : Signature*
    orig_commit_id          : Oid
    orig_path               : LibC::Char*
    orig_start_line_number  : LibC::SizeT
    orig_signature          : Signature*
    orig_committer          : Signature*
    summary                 : LibC::Char*
    boundary                : LibC::Char
  end

  struct BlameLine
    ptr : LibC::Char*
    len : LibC::SizeT
  end

  fun blame_options_init = git_blame_options_init(opts : BlameOptions*, version : LibC::UInt) : LibC::Int

  fun blame_linecount = git_blame_linecount(blame : Blame) : LibC::SizeT
  fun blame_hunkcount = git_blame_hunkcount(blame : Blame) : LibC::SizeT
  fun blame_hunk_byindex = git_blame_hunk_byindex(blame : Blame, index : LibC::SizeT) : BlameHunk*
  fun blame_hunk_byline = git_blame_hunk_byline(blame : Blame, lineno : LibC::SizeT) : BlameHunk*
  fun blame_line_byindex = git_blame_line_byindex(blame : Blame, idx : LibC::SizeT) : BlameLine*

  fun blame_file = git_blame_file(out_blame : Blame*, repo : Repository, path : LibC::Char*, options : BlameOptions*) : LibC::Int
  fun blame_file_from_buffer = git_blame_file_from_buffer(out_blame : Blame*, repo : Repository, path : LibC::Char*, contents : LibC::Char*, contents_len : LibC::SizeT, options : BlameOptions*) : LibC::Int
  fun blame_buffer = git_blame_buffer(out_blame : Blame*, base : Blame, buffer : LibC::Char*, buffer_len : LibC::SizeT) : LibC::Int
  fun blame_free = git_blame_free(blame : Blame)
end
