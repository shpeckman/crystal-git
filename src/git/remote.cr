# src/git/remote.cr
module Git
  struct RemoteHead
    getter name          : String
    getter oid           : Oid
    getter local         : Bool
    getter symref_target : String?

    def initialize(@name : String, @oid : Oid, @local : Bool, @symref_target : String?)
    end

    def ==(other : RemoteHead) : Bool
      @name == other.name && @oid == other.oid && @symref_target == other.symref_target
    end

    def to_s(io : IO) : Nil
      io << @oid.hex[0, 8] << ' ' << @name
      io << " -> " << @symref_target if @symref_target
    end
  end
end
