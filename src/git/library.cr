# src/git/library.cr
module Git::Library
  @@mutex = Mutex.new
  @@count = 0

  def self.acquire : Err?
    @@mutex.synchronize do
      result = LibGit2.libgit2_init
      return Err.capture(result) if result < 0
      @@count += 1
    end
    nil
  end

  def self.release : Nil
    @@mutex.synchronize do
      return if @@count == 0
      @@count -= 1
      LibGit2.libgit2_shutdown
    end
  end
end
