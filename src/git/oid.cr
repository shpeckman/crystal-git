# src/git/oid.cr
module Git
  struct Oid
    getter raw : LibGit2::Oid

    def initialize(@raw : LibGit2::Oid)
    end

    def self.parse(text : String) : Ok(Oid) | Err
      raw = uninitialized LibGit2::Oid
      if err = Git.check(LibGit2.oid_fromstr(pointerof(raw), text))
        return err
      end
      Ok(Oid).new(new(raw))
    end

    def self.from(pointer : LibGit2::Oid*) : Oid
      new(pointer.value)
    end

    def zero? : Bool
      raw = @raw
      LibGit2.oid_is_zero(pointerof(raw)) == 1
    end

    def hex : String
      raw = @raw
      buffer = uninitialized UInt8[41]
      LibGit2.oid_tostr(buffer.to_unsafe, 41_u64, pointerof(raw))
      String.new(buffer.to_unsafe)
    end

    def ==(other : Oid) : Bool
      a = @raw
      b = other.raw
      LibGit2.oid_equal(pointerof(a), pointerof(b)) == 1
    end

    def to_s(io : IO) : Nil
      io << hex
    end
  end
end
