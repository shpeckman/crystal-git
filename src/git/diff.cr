# src/git/diff.cr
module Git
  enum DiffStatus
    Unmodified
    Added
    Deleted
    Modified
    Renamed
    Copied
    Ignored
    Untracked
    Typechange
    Unreadable
    Conflicted

    def self.from_native(value : LibGit2::DeltaType) : DiffStatus
      DiffStatus.new(value.value)
    end
  end

  struct DiffEntry
    getter status   : DiffStatus
    getter old_path : String
    getter new_path : String

    def initialize(@status : DiffStatus, @old_path : String, @new_path : String)
    end

    def path : String
      @new_path.empty? ? @old_path : @new_path
    end

    def ==(other : DiffEntry) : Bool
      @status == other.status && @old_path == other.old_path && @new_path == other.new_path
    end

    def to_s(io : IO) : IO
      io << @status.to_s.downcase << ' ' << @old_path
      io << " -> " << @new_path if @new_path != @old_path
      io
    end
  end
end
