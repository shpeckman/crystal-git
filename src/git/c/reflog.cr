# src/git/c/reflog.cr
@[Link("git2")]
lib LibGit2
  # ============================================================================
  # REFLOG (git2/reflog.h)
  # ============================================================================

  fun reflog_read = git_reflog_read(out_reflog : Reflog*, repo : Repository, name : LibC::Char*) : LibC::Int
  fun reflog_write = git_reflog_write(reflog : Reflog) : LibC::Int
  fun reflog_append = git_reflog_append(reflog : Reflog, id : Oid*, committer : Signature*, msg : LibC::Char*) : LibC::Int
  fun reflog_rename = git_reflog_rename(repo : Repository, old_name : LibC::Char*, name : LibC::Char*) : LibC::Int
  fun reflog_delete = git_reflog_delete(repo : Repository, name : LibC::Char*) : LibC::Int

  fun reflog_entrycount = git_reflog_entrycount(reflog : Reflog) : LibC::SizeT
  fun reflog_entry_byindex = git_reflog_entry_byindex(reflog : Reflog, idx : LibC::SizeT) : ReflogEntry*
  fun reflog_drop = git_reflog_drop(reflog : Reflog, idx : LibC::SizeT, rewrite_previous_entry : LibC::Int) : LibC::Int

  fun reflog_entry_id_old = git_reflog_entry_id_old(entry : ReflogEntry*) : Oid*
  fun reflog_entry_id_new = git_reflog_entry_id_new(entry : ReflogEntry*) : Oid*
  fun reflog_entry_committer = git_reflog_entry_committer(entry : ReflogEntry*) : Signature*
  fun reflog_entry_message = git_reflog_entry_message(entry : ReflogEntry*) : LibC::Char*

  fun reflog_free = git_reflog_free(reflog : Reflog)
end
