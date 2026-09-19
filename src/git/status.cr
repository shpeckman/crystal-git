# src/git/status.cr
module Git
  @[Flags]
  enum EntryStatus : UInt32
    IndexNew           =     1
    IndexModified      =     2
    IndexDeleted       =     4
    IndexRenamed       =     8
    IndexTypechange    =    16
    WorktreeNew        =   128
    WorktreeModified   =   256
    WorktreeDeleted    =   512
    WorktreeTypechange =  1024
    WorktreeRenamed    =  2048
    WorktreeUnreadable =  4096
    Ignored            = 16384
    Conflicted         = 32768
  end

  struct StatusEntry
    getter path   : String
    getter status : EntryStatus

    def initialize(@path : String, @status : EntryStatus)
    end

    def to_s(io : IO) : Nil
      io << path << ' ' << status
    end
  end
end
