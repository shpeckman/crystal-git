# src/git/c/buffer.cr
@[Link("git2")]
lib LibGit2
  # git2/buffer.h
  struct Buf
    ptr      : LibC::Char*
    reserved : LibC::SizeT
    size     : LibC::SizeT
  end

  fun buf_dispose = git_buf_dispose(buffer : Buf*)
end
