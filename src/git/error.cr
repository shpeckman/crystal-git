# src/git/error.cr
module Git
  struct Err
    getter code    : LibGit2::ErrorCode
    getter klass   : LibGit2::ErrorType
    getter message : String

    def initialize(@code : LibGit2::ErrorCode, @klass : LibGit2::ErrorType, @message : String)
    end

    def self.capture(code : LibC::Int) : Err
      raw = LibGit2.err_last
      if raw.null?
        return new(LibGit2::ErrorCode.new(code), LibGit2::ErrorType::NONE, "unknown libgit2 failure")
      end
      entry   = raw.value
      message = entry.message.null? ? "unknown libgit2 failure" : String.new(entry.message)
      new(LibGit2::ErrorCode.new(code), LibGit2::ErrorType.new(entry.klass), message)
    end

    def self.invalid(message : String) : Err
      new(LibGit2::ErrorCode::EINVALID, LibGit2::ErrorType::INVALID, message)
    end

    def ok? : Bool
      false
    end

    def err? : Bool
      true
    end

    def to_s(io : IO) : Nil
      io << message
    end
  end

  struct Ok(T)
    getter value : T

    def initialize(@value : T)
    end

    def ok? : Bool
      true
    end

    def err? : Bool
      false
    end
  end

  def self.check(code : LibC::Int) : Err?
    return nil if code >= 0
    Err.capture(code)
  end
end
