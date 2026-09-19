# src/git/c/signature.cr
@[Link("git2")]
lib LibGit2
  # ============================================================================
  # SIGNATURES (git2/signature.h)
  # ============================================================================

  fun signature_new = git_signature_new(out_sig : Signature**, name : LibC::Char*, email : LibC::Char*, time : Int64, offset : LibC::Int) : LibC::Int
  fun signature_now = git_signature_now(out_sig : Signature**, name : LibC::Char*, email : LibC::Char*) : LibC::Int
  fun signature_default_from_env = git_signature_default_from_env(author_out : Signature**, committer_out : Signature**, repo : Repository) : LibC::Int
  fun signature_default = git_signature_default(out_sig : Signature**, repo : Repository) : LibC::Int
  fun signature_from_buffer = git_signature_from_buffer(out_sig : Signature**, buf : LibC::Char*) : LibC::Int
  fun signature_dup = git_signature_dup(dest : Signature**, sig : Signature*) : LibC::Int
  fun signature_free = git_signature_free(sig : Signature*)
end
