# src/git/graph.cr
module Git
  struct AheadBehind
    getter ahead  : UInt64
    getter behind : UInt64

    def initialize(@ahead : UInt64, @behind : UInt64)
    end

    def ==(other : AheadBehind) : Bool
      @ahead == other.ahead && @behind == other.behind
    end

    def to_s(io : IO) : Nil
      io << @ahead << " ahead, " << @behind << " behind"
    end
  end
end
