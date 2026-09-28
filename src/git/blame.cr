# src/git/blame.cr
module Git
  struct BlameEntry
    getter final_start_line : UInt64
    getter lines            : UInt64
    getter commit           : Oid
    getter author           : String
    getter author_email     : String
    getter summary          : String
    getter orig_path        : String
    getter orig_start_line  : UInt64
    getter boundary         : Bool

    def initialize(@final_start_line : UInt64, @lines : UInt64, @commit : Oid,
                   @author : String, @author_email : String, @summary : String,
                   @orig_path : String, @orig_start_line : UInt64, @boundary : Bool)
    end

    def to_s(io : IO) : Nil
      io << @commit.hex[0, 8] << " (" << @author << ") line " << @final_start_line
      io << '+' << @lines if @lines > 1
    end
  end
end
