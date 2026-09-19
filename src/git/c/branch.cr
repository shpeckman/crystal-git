# src/git/c/branch.cr
@[Link("git2")]
lib LibGit2
  # ============================================================================
  # BRANCHES (git2/branch.h)
  # ============================================================================

  type BranchIterator = Void*

  fun branch_create = git_branch_create(out_ref : Reference*, repo : Repository, branch_name : LibC::Char*, target : Commit, force : LibC::Int) : LibC::Int
  fun branch_create_from_annotated = git_branch_create_from_annotated(ref_out : Reference*, repo : Repository, branch_name : LibC::Char*, target : AnnotatedCommit, force : LibC::Int) : LibC::Int
  fun branch_delete = git_branch_delete(branch : Reference) : LibC::Int

  fun branch_iterator_new = git_branch_iterator_new(out_iter : BranchIterator*, repo : Repository, list_flags : BranchType) : LibC::Int
  fun branch_next = git_branch_next(out_ref : Reference*, out_type : BranchType*, iter : BranchIterator) : LibC::Int
  fun branch_iterator_free = git_branch_iterator_free(iter : BranchIterator)

  fun branch_move = git_branch_move(out_ref : Reference*, branch : Reference, new_branch_name : LibC::Char*, force : LibC::Int) : LibC::Int
  fun branch_lookup = git_branch_lookup(out_ref : Reference*, repo : Repository, branch_name : LibC::Char*, branch_type : BranchType) : LibC::Int
  fun branch_name = git_branch_name(out_name : LibC::Char**, ref : Reference) : LibC::Int

  fun branch_upstream = git_branch_upstream(out_ref : Reference*, branch : Reference) : LibC::Int
  fun branch_set_upstream = git_branch_set_upstream(branch : Reference, branch_name : LibC::Char*) : LibC::Int
  fun branch_upstream_name = git_branch_upstream_name(out_buf : Buf*, repo : Repository, refname : LibC::Char*) : LibC::Int

  fun branch_is_head = git_branch_is_head(branch : Reference) : LibC::Int
  fun branch_is_checked_out = git_branch_is_checked_out(branch : Reference) : LibC::Int

  fun branch_remote_name = git_branch_remote_name(out_buf : Buf*, repo : Repository, refname : LibC::Char*) : LibC::Int
  fun branch_upstream_remote = git_branch_upstream_remote(buf : Buf*, repo : Repository, refname : LibC::Char*) : LibC::Int
  fun branch_upstream_merge = git_branch_upstream_merge(buf : Buf*, repo : Repository, refname : LibC::Char*) : LibC::Int

  fun branch_name_is_valid = git_branch_name_is_valid(valid : LibC::Int*, name : LibC::Char*) : LibC::Int
end
