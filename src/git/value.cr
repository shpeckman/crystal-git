# src/git/value.cr
module Git
  alias Value = Nil |
                Bool |
                Int32 |
                UInt64 |
                String |
                Oid |
                MergeOutcome |
                AheadBehind |
                Array(String) |
                Array(StatusEntry) |
                Array(StashEntry) |
                Array(ConflictEntry) |
                Array(Oid)

  alias Outcome = Ok(Value) | Err

  struct Slot(T)
    getter index : Int32

    def initialize(@index : Int32)
    end

    def valid? : Bool
      @index >= 0
    end
  end

  struct Report
    getter outcomes : Array(Outcome)
    getter error    : Err?

    def initialize(@outcomes : Array(Outcome), @error : Err?)
    end

    def ok? : Bool
      @error.nil?
    end

    def size : Int32
      @outcomes.size
    end
  end
end
