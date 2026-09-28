# src/git/linked_worktree.cr
module Git
  struct LinkedWorktree
    getter name   : String
    getter path   : String
    getter locked : Bool

    def initialize(@name : String, @path : String, @locked : Bool)
    end

    def ==(other : LinkedWorktree) : Bool
      @name == other.name && @path == other.path
    end

    def to_s(io : IO) : Nil
      io << @name << ' ' << @path
      io << " (locked)" if @locked
    end
  end
end
