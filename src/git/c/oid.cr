# src/git/c/oid.cr
@[Link("git2")]
lib LibGit2
  # git2/oid.h
  enum OidType
    SHA1   = 1
    SHA256 = 2
  end

  struct Oid
    id : StaticArray(UInt8, 20)
  end

  type OidShorten = Void*

  fun oid_fromstr = git_oid_fromstr(out_oid : Oid*, str : LibC::Char*) : LibC::Int
  fun oid_fromstrn = git_oid_fromstrn(out_oid : Oid*, str : LibC::Char*, length : LibC::SizeT) : LibC::Int
  fun oid_fromstrp = git_oid_fromstrp(out_oid : Oid*, str : LibC::Char*) : LibC::Int
  fun oid_fromraw = git_oid_fromraw(out_oid : Oid*, raw : UInt8*) : LibC::Int
  fun oid_fmt = git_oid_fmt(out_str : LibC::Char*, id : Oid*) : LibC::Int
  fun oid_nfmt = git_oid_nfmt(out_str : LibC::Char*, n : LibC::SizeT, id : Oid*) : LibC::Int
  fun oid_pathfmt = git_oid_pathfmt(out_str : LibC::Char*, id : Oid*) : LibC::Int
  fun oid_tostr_s = git_oid_tostr_s(oid : Oid*) : LibC::Char*
  fun oid_tostr = git_oid_tostr(out_str : LibC::Char*, n : LibC::SizeT, id : Oid*) : LibC::Char*
  fun oid_cpy = git_oid_cpy(out_oid : Oid*, src : Oid*) : LibC::Int
  fun oid_cmp = git_oid_cmp(a : Oid*, b : Oid*) : LibC::Int
  fun oid_equal = git_oid_equal(a : Oid*, b : Oid*) : LibC::Int
  fun oid_ncmp = git_oid_ncmp(a : Oid*, b : Oid*, len : LibC::SizeT) : LibC::Int
  fun oid_streq = git_oid_streq(id : Oid*, str : LibC::Char*) : LibC::Int
  fun oid_strcmp = git_oid_strcmp(id : Oid*, str : LibC::Char*) : LibC::Int
  fun oid_is_zero = git_oid_is_zero(id : Oid*) : LibC::Int

  fun oid_shorten_new = git_oid_shorten_new(min_length : LibC::SizeT) : OidShorten
  fun oid_shorten_add = git_oid_shorten_add(os : OidShorten, text_id : LibC::Char*) : LibC::Int
  fun oid_shorten_free = git_oid_shorten_free(os : OidShorten)
end
