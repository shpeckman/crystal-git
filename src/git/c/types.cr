# src/git/c/types.cr
@[Link("git2")]
lib LibGit2
  # git2/types.h Opaque Types
  type AnnotatedCommit = Void*
  type Blame = Void*
  type Blob = Void*
  type Commit = Void*
  type CommitGraph = Void*
  type CommitGraphWriter = Void*
  type Config = Void*
  type ConfigBackend = Void*
  type Cert = Void*
  type Index = Void*
  type IndexConflictIterator = Void*
  type IndexIterator = Void*
  type Mailmap = Void*
  type MidxWriter = Void*
  type Note = Void*
  type Object = Void*
  type Odb = Void*
  type OdbBackend = Void*
  type OdbObject = Void*
  type OdbStream = Void*
  type OdbWritepack = Void*
  type Packbuilder = Void*
  type Push = Void*
  type Rebase = Void*
  type Refdb = Void*
  type RefdbBackend = Void*
  type Reference = Void*
  type ReferenceIterator = Void*
  type Reflog = Void*
  type ReflogEntry = Void*
  type Refspec = Void*
  type Remote = Void*
  type RemoteCallbacks = Void*
  type RemoteHead = Void*
  type Repository = Void*
  type Revwalk = Void*
  type StatusList = Void*
  type Submodule = Void*
  type Tag = Void*
  type Transaction = Void*
  type Transport = Void*
  type Tree = Void*
  type Treebuilder = Void*
  type TreeEntry = Void*
  type Worktree = Void*
  type Writestream = Void*

  # git2/types.h Common Structs
  struct Time
    time   : Int64
    offset : LibC::Int
    sign   : LibC::Char
  end

  struct Signature
    name  : LibC::Char*
    email : LibC::Char*
    when  : Time
  end

  # git2/commit.h (Required by Repository)
  struct CommitArray
    commits : Commit**
    count   : LibC::SizeT
  end

  # git2/types.h Enums
  enum ObjectType
    ANY     = -2
    INVALID = -1
    COMMIT  =  1
    TREE    =  2
    BLOB    =  3
    TAG     =  4
  end

  enum ReferenceType
    INVALID  = 0
    DIRECT   = 1
    SYMBOLIC = 2
    ALL      = 3
  end

  enum BranchType
    LOCAL  = 1
    REMOTE = 2
    ALL    = 3
  end

  enum FilemodeType
    UNREADABLE      =     0
    TREE            = 16384 # 0040000
    BLOB            = 33188 # 0100644
    BLOB_EXECUTABLE = 33261 # 0100755
    LINK            = 40960 # 0120000
    COMMIT          = 57344 # 0160000
  end

  enum SubmoduleUpdateType
    CHECKOUT = 1
    REBASE   = 2
    MERGE    = 3
    NONE     = 4
    DEFAULT  = 0
  end

  enum SubmoduleIgnoreType
    UNSPECIFIED = -1
    NONE        =  1
    UNTRACKED   =  2
    DIRTY       =  3
    ALL         =  4
  end

  enum SubmoduleRecurseType
    NO       = 0
    YES      = 1
    ONDEMAND = 2
  end

  # git2/refdb.h Enums (Required by Repository)
  enum RefdbType
    FILES    = 1
    REFTABLE = 2
  end
end
