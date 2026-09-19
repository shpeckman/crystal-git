# src/git/state.cr
module Git
  enum State
    Clean                =  0
    Merge                =  1
    Revert               =  2
    RevertSequence       =  3
    Cherrypick           =  4
    CherrypickSequence   =  5
    Bisect               =  6
    Rebase               =  7
    RebaseInteractive    =  8
    RebaseMerge          =  9
    ApplyMailbox         = 10
    ApplyMailboxOrRebase = 11

    def self.from_native(value : LibC::Int) : State
      return State::Clean if value < 0 || value > 11
      State.new(value)
    end

    def to_set : StateSet
      StateSet.new(1_u16 << value)
    end
  end

  @[Flags]
  enum StateSet : UInt16
    Clean
    Merge
    Revert
    RevertSequence
    Cherrypick
    CherrypickSequence
    Bisect
    Rebase
    RebaseInteractive
    RebaseMerge
    ApplyMailbox
    ApplyMailboxOrRebase
  end

  @[Flags]
  enum Predicate : UInt32
    Bare
    UnbornHead
    DetachedHead
    Conflicted
    DirtyIndex
  end

  enum Reversibility
    ReadOnly
    RefOnly
    IndexOnly
    Worktree
    External
  end

  struct Conditions
    getter state      : State
    getter predicates : Predicate

    def initialize(@state : State, @predicates : Predicate)
    end

    def advance(descriptor : Descriptor) : Conditions
      next_state = descriptor.leaves || @state
      Conditions.new(next_state, (@predicates | descriptor.sets) & ~descriptor.clears)
    end
  end
end
