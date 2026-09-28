# src/git/flags.cr
module Git
  @[Flags]
  enum StageFlag : UInt32
    Force                = 1
    DisablePathspecMatch = 2
    CheckPathspec        = 4
  end

  @[Flags]
  enum CheckoutFlag : UInt32
    Force                 =        2
    RecreateMissing       =        4
    AllowConflicts        =       16
    RemoveUntracked       =       32
    RemoveIgnored         =       64
    UpdateOnly            =      128
    DontUpdateIndex       =      256
    NoRefresh             =      512
    SkipUnmerged          =     1024
    UseOurs               =     2048
    UseTheirs             =     4096
    DisablePathspecMatch  =     8192
    UpdateSubmodules      =    65536
    SkipLockedDirectories =   262144
    DontOverwriteIgnored  =   524288
    DontRemoveExisting    =  4194304
    DryRun                = 16777216
  end

  @[Flags]
  enum StatusFlag : UInt32
    IncludeUntracked      =    1
    IncludeIgnored        =    2
    IncludeUnmodified     =    4
    ExcludeSubmodules     =    8
    RecurseUntrackedDirs  =   16
    DisablePathspecMatch  =   32
    RecurseIgnoredDirs    =   64
    RenamesHeadToIndex    =  128
    RenamesIndexToWorkdir =  256
    RenamesFromRewrites   = 2048
    NoRefresh             = 4096
    UpdateIndex           = 8192
  end

  @[Flags]
  enum BranchFlag : UInt32
    Force = 1
  end

  @[Flags]
  enum TagFlag : UInt32
    Force = 1
  end

  @[Flags]
  enum MergeFlag : UInt32
    FindRenames    = 1
    FailOnConflict = 2
    SkipReuc       = 4
    NoRecursive    = 8
  end

  @[Flags]
  enum StashFlag : UInt32
    KeepIndex        = 1
    IncludeUntracked = 2
    IncludeIgnored   = 4
    KeepAll          = 8
  end

  @[Flags]
  enum StashApplyFlag : UInt32
    ReinstateIndex = 1
  end

  enum ResetMode
    Soft  = 1
    Mixed = 2
    Hard  = 3

    def to_native : LibGit2::ResetType
      LibGit2::ResetType.new(value)
    end
  end

  enum Prune
    Default = 0
    Yes     = 1
    No      = 2

    def to_native : LibGit2::FetchPrune
      LibGit2::FetchPrune.new(value)
    end
  end

  enum ApplyLocation
    Workdir = 0
    Index   = 1
    Both    = 2

    def to_native : LibGit2::ApplyLocation
      LibGit2::ApplyLocation.new(value)
    end
  end
end
