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
    getter status     : DiffStatus
    getter old_path   : String
    getter new_path   : String
    getter similarity : Int32

    def initialize(@status : DiffStatus, @old_path : String, @new_path : String, @similarity : Int32 = 0)
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

  struct DiffStats
    getter files_changed : Int32
    getter insertions    : Int32
    getter deletions     : Int32

    def initialize(@files_changed : Int32, @insertions : Int32, @deletions : Int32)
    end

    def total : Int32
      @insertions + @deletions
    end

    def ==(other : DiffStats) : Bool
      @files_changed == other.files_changed &&
        @insertions == other.insertions &&
        @deletions == other.deletions
    end

    def to_s(io : IO) : Nil
      io << @files_changed << " files changed, "
      io << @insertions << " insertions(+), "
      io << @deletions << " deletions(-)"
    end
  end

  enum LineOrigin
    Context
    Addition
    Deletion
    ContextEofnl
    AddEofnl
    DelEofnl
    FileHeader
    HunkHeader
    Binary
    Other

    def self.from_native(origin : LibC::Char) : LineOrigin
      case origin.to_i32
      when 32 then Context
      when 43 then Addition
      when 45 then Deletion
      when 61 then ContextEofnl
      when 62 then AddEofnl
      when 60 then DelEofnl
      when 70 then FileHeader
      when 72 then HunkHeader
      when 66 then Binary
      else         Other
      end
    end
  end

  struct DiffLineInfo
    getter origin     : LineOrigin
    getter old_lineno : Int32?
    getter new_lineno : Int32?
    getter content    : String

    def initialize(@origin : LineOrigin, @old_lineno : Int32?, @new_lineno : Int32?, @content : String)
    end

    def context? : Bool
      @origin.context?
    end

    def addition? : Bool
      @origin.addition?
    end

    def deletion? : Bool
      @origin.deletion?
    end

    def ==(other : DiffLineInfo) : Bool
      @origin == other.origin && @old_lineno == other.old_lineno &&
        @new_lineno == other.new_lineno && @content == other.content
    end

    def to_s(io : IO) : Nil
      case @origin
      when .addition? then io << '+'
      when .deletion? then io << '-'
      when .context?  then io << ' '
      else                 io << @origin.to_s[0]
      end
      io << @content
    end
  end

  struct DiffHunkInfo
    getter header    : String
    getter old_start : Int32
    getter old_lines : Int32
    getter new_start : Int32
    getter new_lines : Int32
    getter lines     : Array(DiffLineInfo)

    def initialize(@header : String, @old_start : Int32, @old_lines : Int32,
                   @new_start : Int32, @new_lines : Int32, @lines : Array(DiffLineInfo))
    end

    def ==(other : DiffHunkInfo) : Bool
      @header == other.header && @old_start == other.old_start &&
        @new_start == other.new_start && @lines == other.lines
    end

    def to_s(io : IO) : Nil
      io << @header
      @lines.each { |line| io << line }
    end
  end

  struct FilePatch
    getter status     : DiffStatus
    getter old_path   : String
    getter new_path   : String
    getter similarity : Int32
    getter hunks      : Array(DiffHunkInfo)

    def initialize(@status : DiffStatus, @old_path : String, @new_path : String,
                   @similarity : Int32, @hunks : Array(DiffHunkInfo))
    end

    def path : String
      @new_path.empty? ? @old_path : @new_path
    end

    def binary? : Bool
      @hunks.empty?
    end

    def ==(other : FilePatch) : Bool
      @status == other.status && @old_path == other.old_path &&
        @new_path == other.new_path && @hunks == other.hunks
    end

    def to_s(io : IO) : Nil
      io << @status.to_s.downcase << ' ' << @old_path
      io << " -> " << @new_path if @new_path != @old_path
      @hunks.each { |hunk| io << '\n' << hunk }
    end
  end

  enum DiffOutput
    Entries
    Patch
    Stats
    Files
  end
end
