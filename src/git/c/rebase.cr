# src/git/c/rebase.cr
@[Link("git2")]
lib LibGit2
  # ============================================================================
  # REBASE (git2/rebase.h)
  # ============================================================================

  enum RebaseOperationType
    PICK   = 0
    REWORD = 1
    EDIT   = 2
    SQUASH = 3
    FIXUP  = 4
    EXEC   = 5
  end

  struct RebaseOperation
    type : RebaseOperationType
    id   : Oid
    exec : LibC::Char*
  end

  struct RebaseOptions
    version           : LibC::UInt
    quiet             : LibC::Int
    inmemory          : LibC::Int
    rewrite_notes_ref : LibC::Char*
    merge_options     : MergeOptions
    checkout_options  : CheckoutOptions
    commit_create_cb  : CommitCreateCb
    signing_cb        : Void*
    payload           : Void*
  end

  fun rebase_options_init = git_rebase_options_init(opts : RebaseOptions*, version : LibC::UInt) : LibC::Int
  fun rebase_init = git_rebase_init(out_rebase : Rebase*, repo : Repository, branch : AnnotatedCommit, upstream : AnnotatedCommit, onto : AnnotatedCommit, opts : RebaseOptions*) : LibC::Int
  fun rebase_open = git_rebase_open(out_rebase : Rebase*, repo : Repository, opts : RebaseOptions*) : LibC::Int

  fun rebase_orig_head_name = git_rebase_orig_head_name(rebase : Rebase) : LibC::Char*
  fun rebase_orig_head_id = git_rebase_orig_head_id(rebase : Rebase) : Oid*
  fun rebase_onto_name = git_rebase_onto_name(rebase : Rebase) : LibC::Char*
  fun rebase_onto_id = git_rebase_onto_id(rebase : Rebase) : Oid*

  fun rebase_operation_entrycount = git_rebase_operation_entrycount(rebase : Rebase) : LibC::SizeT
  fun rebase_operation_current = git_rebase_operation_current(rebase : Rebase) : LibC::SizeT
  fun rebase_operation_byindex = git_rebase_operation_byindex(rebase : Rebase, idx : LibC::SizeT) : RebaseOperation*

  fun rebase_next = git_rebase_next(operation : RebaseOperation**, rebase : Rebase) : LibC::Int
  fun rebase_inmemory_index = git_rebase_inmemory_index(index : Index*, rebase : Rebase) : LibC::Int
  fun rebase_commit = git_rebase_commit(id : Oid*, rebase : Rebase, author : Signature*, committer : Signature*, message_encoding : LibC::Char*, message : LibC::Char*) : LibC::Int
  fun rebase_abort = git_rebase_abort(rebase : Rebase) : LibC::Int
  fun rebase_finish = git_rebase_finish(rebase : Rebase, signature : Signature*) : LibC::Int
  fun rebase_free = git_rebase_free(rebase : Rebase)
end
