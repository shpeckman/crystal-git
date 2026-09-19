# src/git/c/strarray.cr
@[Link("git2")]
lib LibGit2
  # git2/strarray.h
  struct Strarray
    strings : LibC::Char**
    count   : LibC::SizeT
  end

  fun strarray_dispose = git_strarray_dispose(array : Strarray*)
end
