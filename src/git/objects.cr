# src/git/objects.cr
module Git
  enum ObjectKind
    Commit = 1
    Tree   = 2
    Blob   = 3
    Tag    = 4

    def self.from_native(value : LibGit2::ObjectType) : ObjectKind?
      ObjectKind.from_value?(value.value)
    end
  end

  struct ObjectData
    getter kind  : ObjectKind
    getter bytes : Bytes

    def initialize(@kind : ObjectKind, @bytes : Bytes)
    end

    def size : Int32
      @bytes.size
    end

    def text : String
      String.new(@bytes)
    end
  end

  struct TreeEntryInfo
    getter path : String
    getter name : String
    getter kind : ObjectKind
    getter mode : UInt32
    getter oid  : Oid

    def initialize(@path : String, @name : String, @kind : ObjectKind, @mode : UInt32, @oid : Oid)
    end

    def tree? : Bool
      @kind.tree?
    end

    def blob? : Bool
      @kind.blob?
    end

    def submodule? : Bool
      @kind.commit?
    end

    def ==(other : TreeEntryInfo) : Bool
      @path == other.path && @kind == other.kind && @mode == other.mode && @oid == other.oid
    end

    def to_s(io : IO) : Nil
      io << @mode.to_s(8).rjust(6, '0') << ' ' << @kind.to_s.downcase << ' ' << @oid.hex << '\t' << @path
    end
  end
end
