# src/git/stream.cr
module Git
  class Stream
    enum Phase
      Building
      Validated
      Running
      Halted
      Completed
      RolledBack
      Sealed
    end

    enum RollbackMode
      UndoLog
      Snapshot
    end

    struct Plan
      getter mode         : RollbackMode
      getter conditions   : Conditions
      getter size         : Int32
      getter irreversible : Bool

      def initialize(@mode : RollbackMode, @conditions : Conditions, @size : Int32, @irreversible : Bool)
      end
    end

    getter phase : Phase

    def initialize(@repo : Repo, @allow_irreversible : Bool = false)
      @commands    = [] of Command
      @values      = [] of Value
      @undo        = [] of Undo
      @cursor      = 0
      @phase       = Phase::Building
      @plan        = nil.as(Plan?)
      @snapshot    = nil.as(Snapshot?)
      @build_error = nil.as(Err?)
    end

    def stage(pathspec : String) : Slot(UInt64)
      queue_stage([pathspec], StageFlag::None)
    end

    def stage(pathspec : String, *flags : StageFlag) : Slot(UInt64)
      queue_stage([pathspec], mask(flags, StageFlag::None))
    end

    def stage(pathspec : Array(String)) : Slot(UInt64)
      queue_stage(pathspec, StageFlag::None)
    end

    def stage(pathspec : Array(String), *flags : StageFlag) : Slot(UInt64)
      queue_stage(pathspec, mask(flags, StageFlag::None))
    end

    def unstage(pathspec : String) : Slot(Int32)
      Slot(Int32).new(queue(Commands::Unstage.new([pathspec])))
    end

    def unstage(pathspec : Array(String)) : Slot(Int32)
      Slot(Int32).new(queue(Commands::Unstage.new(pathspec)))
    end

    def remove(pathspec : String) : Slot(UInt64)
      Slot(UInt64).new(queue(Commands::Remove.new([pathspec])))
    end

    def remove(pathspec : Array(String)) : Slot(UInt64)
      Slot(UInt64).new(queue(Commands::Remove.new(pathspec)))
    end

    def commit(message : String) : Slot(Oid)
      Slot(Oid).new(queue(Commands::Commit.new(message)))
    end

    def set_head(refname : String) : Slot(String)
      Slot(String).new(queue(Commands::SetHead.new(refname)))
    end

    def checkout(target : String) : Slot(String)
      queue_checkout(target, CheckoutFlag::None)
    end

    def checkout(target : String, *flags : CheckoutFlag) : Slot(String)
      queue_checkout(target, mask(flags, CheckoutFlag::None))
    end

    def reset(target : String, mode : ResetMode) : Slot(Oid)
      Slot(Oid).new(queue(Commands::Reset.new(target, mode)))
    end

    def create_branch(name : String, target : String = "HEAD") : Slot(Oid)
      queue_create_branch(name, target, BranchFlag::None)
    end

    def create_branch(name : String, target : String = "HEAD", *flags : BranchFlag) : Slot(Oid)
      queue_create_branch(name, target, mask(flags, BranchFlag::None))
    end

    def delete_branch(name : String) : Slot(String)
      Slot(String).new(queue(Commands::DeleteBranch.new(name)))
    end

    def move_branch(name : String, new_name : String) : Slot(String)
      queue_move_branch(name, new_name, BranchFlag::None)
    end

    def move_branch(name : String, new_name : String, *flags : BranchFlag) : Slot(String)
      queue_move_branch(name, new_name, mask(flags, BranchFlag::None))
    end

    def set_upstream(branch : String, upstream : String? = nil) : Slot(String)
      Slot(String).new(queue(Commands::SetUpstream.new(branch, upstream)))
    end

    def tag(name : String, target : String = "HEAD", *, message : String? = nil) : Slot(Oid)
      queue_tag(name, target, message, TagFlag::None)
    end

    def tag(name : String, target : String = "HEAD", *flags : TagFlag, message : String? = nil) : Slot(Oid)
      queue_tag(name, target, message, mask(flags, TagFlag::None))
    end

    def delete_tag(name : String) : Slot(String)
      Slot(String).new(queue(Commands::DeleteTag.new(name)))
    end

    def merge(target : String) : Slot(MergeOutcome)
      queue_merge(target, MergeFlag::None)
    end

    def merge(target : String, *flags : MergeFlag) : Slot(MergeOutcome)
      queue_merge(target, mask(flags, MergeFlag::None))
    end

    def cherry_pick(target : String, *, mainline : UInt32 = 0_u32) : Slot(Oid)
      queue_cherry_pick(target, mainline, MergeFlag::None)
    end

    def cherry_pick(target : String, *flags : MergeFlag, mainline : UInt32 = 0_u32) : Slot(Oid)
      queue_cherry_pick(target, mainline, mask(flags, MergeFlag::None))
    end

    def revert(target : String, *, mainline : UInt32 = 0_u32) : Slot(Oid)
      queue_revert(target, mainline, MergeFlag::None)
    end

    def revert(target : String, *flags : MergeFlag, mainline : UInt32 = 0_u32) : Slot(Oid)
      queue_revert(target, mainline, mask(flags, MergeFlag::None))
    end

    def abort_integration : Slot(Oid)
      Slot(Oid).new(queue(Commands::AbortIntegration.new))
    end

    def rebase(upstream : String, onto : String? = nil, branch : String? = nil) : Slot(UInt64)
      Slot(UInt64).new(queue(Commands::Rebase.new(upstream, onto, branch)))
    end

    def abort_rebase : Slot(Bool)
      Slot(Bool).new(queue(Commands::AbortRebase.new))
    end

    def stash(*, message : String? = nil) : Slot(Oid)
      queue_stash(message, StashFlag::None)
    end

    def stash(*flags : StashFlag, message : String? = nil) : Slot(Oid)
      queue_stash(message, mask(flags, StashFlag::None))
    end

    def stash_apply(position : Int32 = 0) : Slot(Int32)
      queue_stash_apply(position, StashApplyFlag::None)
    end

    def stash_apply(position : Int32 = 0, *flags : StashApplyFlag) : Slot(Int32)
      queue_stash_apply(position, mask(flags, StashApplyFlag::None))
    end

    def stash_pop(position : Int32 = 0) : Slot(Int32)
      queue_stash_pop(position, StashApplyFlag::None)
    end

    def stash_pop(position : Int32 = 0, *flags : StashApplyFlag) : Slot(Int32)
      queue_stash_pop(position, mask(flags, StashApplyFlag::None))
    end

    def stash_drop(position : Int32 = 0) : Slot(Int32)
      Slot(Int32).new(queue(Commands::Drop.new(position)))
    end

    def stash_list : Slot(Array(StashEntry))
      Slot(Array(StashEntry)).new(queue(Commands::ListStash.new))
    end

    def fetch(remote : String = "origin", refspecs : Array(String) = [] of String, prune : Prune = Prune::Default) : Slot(String)
      Slot(String).new(queue(Commands::Fetch.new(remote, refspecs, prune)))
    end

    def push(remote : String = "origin", refspecs : Array(String) = [] of String) : Slot(String)
      Slot(String).new(queue(Commands::Push.new(remote, refspecs)))
    end

    def status : Slot(Array(StatusEntry))
      queue_status(StatusFlag::None)
    end

    def status(*flags : StatusFlag) : Slot(Array(StatusEntry))
      queue_status(mask(flags, StatusFlag::None))
    end

    def list_branches(kind : LibGit2::BranchType = LibGit2::BranchType::LOCAL) : Slot(Array(String))
      Slot(Array(String)).new(queue(Commands::ListBranches.new(kind)))
    end

    def list_tags : Slot(Array(String))
      Slot(Array(String)).new(queue(Commands::ListTags.new))
    end

    def [](slot : Slot(T)) : T? forall T
      return nil unless slot.valid?
      @values[slot.index]?.as?(T)
    end

    def size : Int32
      @commands.size
    end

    def validate : Ok(Plan) | Err
      if err = @build_error
        return err
      end
      unless @phase.building? || @phase.validated?
        return Err.invalid("stream cannot be validated while #{@phase}")
      end
      if @commands.empty?
        return Err.invalid("stream is empty")
      end

      snapshot = @repo.conditions
      return snapshot if snapshot.is_a?(Err)
      current       = snapshot.value
      reversibility = Reversibility::ReadOnly
      irreversible  = nil.as(Symbol?)

      @commands.each do |command|
        entry = command.descriptor
        if err = guard(entry, current)
          return err
        end
        if entry.reversibility.external?
          irreversible ||= entry.name
        elsif entry.reversibility.value > reversibility.value
          reversibility = entry.reversibility
        end
        current = current.advance(entry)
      end

      if name = irreversible
        unless @allow_irreversible
          return Err.invalid("#{name} cannot be rolled back; build the stream with allow_irreversible: true")
        end
      end

      mode = reversibility.worktree? ? RollbackMode::Snapshot : RollbackMode::UndoLog

      if mode.snapshot?
        origin = snapshot.value
        if origin.predicates.bare?
          return Err.invalid("worktree commands require a non-bare repository")
        end
        if origin.predicates.unborn_head?
          return Err.invalid("worktree commands require a born HEAD to snapshot")
        end
      end

      plan   = Plan.new(mode, current, @commands.size, !irreversible.nil?)
      @plan  = plan
      @phase = Phase::Validated
      Ok(Plan).new(plan)
    end

    def step : Outcome?
      return nil if @phase.completed?

      unless @phase.running?
        if err = start
          @phase = Phase::Halted
          return err
        end
      end

      return nil if @cursor >= @commands.size

      command = @commands[@cursor]
      live    = @repo.conditions
      if live.is_a?(Err)
        @phase = Phase::Halted
        return live
      end

      if err = guard(command.descriptor, live.value)
        @phase = Phase::Halted
        return err
      end

      outcome = command.execute(@repo, @undo)
      if outcome.is_a?(Err)
        @phase = Phase::Halted
        return outcome
      end

      @values[@cursor] = outcome.value
      @cursor += 1
      @phase = Phase::Completed if @cursor >= @commands.size
      outcome
    end

    def run : Report
      outcomes = [] of Outcome
      failure  = nil.as(Err?)
      while outcome = step
        outcomes << outcome
        if outcome.is_a?(Err)
          failure = outcome
          break
        end
      end
      Report.new(outcomes, failure)
    end

    def rollback : Err?
      if @phase.building? || @phase.sealed? || @phase.rolled_back?
        return Err.invalid("stream has nothing to roll back while #{@phase}")
      end

      failure = nil.as(Err?)
      while record = @undo.pop?
        if err = record.apply(@repo)
          failure ||= err
        end
      end

      if snapshot = @snapshot
        if err = snapshot.restore(@repo)
          failure ||= err
        end
      end

      @phase = Phase::RolledBack
      failure
    end

    def seal : Err?
      failure = nil.as(Err?)
      if snapshot = @snapshot
        failure = snapshot.discard(@repo) unless @phase.rolled_back?
      end
      @undo.clear
      @snapshot = nil
      @phase    = Phase::Sealed
      failure
    end

    def sealed? : Bool
      @phase.sealed?
    end

    private def queue_stage(pathspec : Array(String), flags : StageFlag) : Slot(UInt64)
      Slot(UInt64).new(queue(Commands::Stage.new(pathspec, flags)))
    end

    private def queue_checkout(target : String, flags : CheckoutFlag) : Slot(String)
      Slot(String).new(queue(Commands::Checkout.new(target, flags)))
    end

    private def queue_create_branch(name : String, target : String, flags : BranchFlag) : Slot(Oid)
      Slot(Oid).new(queue(Commands::CreateBranch.new(name, target, flags)))
    end

    private def queue_move_branch(name : String, new_name : String, flags : BranchFlag) : Slot(String)
      Slot(String).new(queue(Commands::MoveBranch.new(name, new_name, flags)))
    end

    private def queue_tag(name : String, target : String, message : String?, flags : TagFlag) : Slot(Oid)
      Slot(Oid).new(queue(Commands::Tag.new(name, target, message, flags)))
    end

    private def queue_merge(target : String, flags : MergeFlag) : Slot(MergeOutcome)
      Slot(MergeOutcome).new(queue(Commands::Merge.new(target, flags)))
    end

    private def queue_cherry_pick(target : String, mainline : UInt32, flags : MergeFlag) : Slot(Oid)
      Slot(Oid).new(queue(Commands::CherryPick.new(target, mainline, flags)))
    end

    private def queue_revert(target : String, mainline : UInt32, flags : MergeFlag) : Slot(Oid)
      Slot(Oid).new(queue(Commands::Revert.new(target, mainline, flags)))
    end

    private def queue_stash(message : String?, flags : StashFlag) : Slot(Oid)
      Slot(Oid).new(queue(Commands::Save.new(message, flags)))
    end

    private def queue_stash_apply(position : Int32, flags : StashApplyFlag) : Slot(Int32)
      Slot(Int32).new(queue(Commands::Apply.new(position, flags)))
    end

    private def queue_stash_pop(position : Int32, flags : StashApplyFlag) : Slot(Int32)
      Slot(Int32).new(queue(Commands::Pop.new(position, flags)))
    end

    private def queue_status(flags : StatusFlag) : Slot(Array(StatusEntry))
      Slot(Array(StatusEntry)).new(queue(Commands::Status.new(flags)))
    end

    private def start : Err?
      case @phase
      when .building?, .validated?
        result = validate
        return result if result.is_a?(Err)
        plan = result.value

        if plan.mode.snapshot?
          captured = Snapshot.capture(@repo)
          return captured if captured.is_a?(Err)
          @snapshot = captured.value
        end

        @values = Array(Value).new(@commands.size, nil)
        @cursor = 0
        @phase  = Phase::Running
        nil
      when .halted?
        Err.invalid("stream halted; roll back or seal it")
      else
        Err.invalid("stream cannot run while #{@phase}")
      end
    end

    private def guard(entry : Descriptor, conditions : Conditions) : Err?
      unless entry.legal_in.includes?(conditions.state.to_set)
        return Err.invalid("#{entry.name} is illegal while the repository is in #{conditions.state} state")
      end
      missing = entry.requires & ~conditions.predicates
      unless missing.none?
        return Err.invalid("#{entry.name} requires #{missing}")
      end
      blocked = entry.forbids & conditions.predicates
      unless blocked.none?
        return Err.invalid("#{entry.name} is blocked by #{blocked}")
      end
      nil
    end

    private def queue(command : Command) : Int32
      unless @phase.building?
        @build_error ||= Err.invalid("stream is no longer accepting commands")
        return -1
      end
      @commands << command
      @commands.size - 1
    end

    private def mask(flags : Tuple, empty : T) : T forall T
      result = empty
      flags.each { |flag| result |= flag }
      result
    end
  end
end
