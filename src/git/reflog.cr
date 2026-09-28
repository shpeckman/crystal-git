# src/git/reflog.cr
module Git
  struct ReflogEntry
    getter old_oid        : Oid
    getter new_oid        : Oid
    getter committer      : String
    getter committer_mail : String
    getter message        : String

    def initialize(@old_oid : Oid, @new_oid : Oid, @committer : String, @committer_mail : String, @message : String)
    end

    def ==(other : ReflogEntry) : Bool
      @old_oid == other.old_oid && @new_oid == other.new_oid && @message == other.message
    end

    def to_s(io : IO) : Nil
      io << @new_oid.hex[0, 8] << ' ' << @message
    end
  end
end
