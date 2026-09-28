# src/git/note.cr
module Git
  struct NoteEntry
    getter object : Oid
    getter blob   : Oid

    def initialize(@object : Oid, @blob : Oid)
    end

    def ==(other : NoteEntry) : Bool
      @object == other.object && @blob == other.blob
    end

    def to_s(io : IO) : Nil
      io << @blob.hex[0, 8] << ' ' << @object.hex
    end
  end

  struct Note
    getter object       : Oid
    getter blob         : Oid
    getter message      : String
    getter author       : String
    getter author_email : String

    def initialize(@object : Oid, @blob : Oid, @message : String, @author : String, @author_email : String)
    end

    def ==(other : Note) : Bool
      @object == other.object && @message == other.message
    end

    def to_s(io : IO) : Nil
      io << @object.hex[0, 8] << ": " << @message
    end
  end
end
