# src/git/mailmap.cr
module Git
  struct Identity
    getter name  : String
    getter email : String

    def initialize(@name : String, @email : String)
    end

    def ==(other : Identity) : Bool
      @name == other.name && @email == other.email
    end

    def to_s(io : IO) : Nil
      io << @name << " <" << @email << '>'
    end
  end
end
