# src/git/commands/graph.cr
module Git::Commands
  class AheadBehind < Command
    describe(:ahead_behind, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::ReadOnly)

    def initialize(@local : String, @upstream : String)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      local_oid = Native.oid(repo, @local)
      return local_oid if local_oid.is_a?(Err)

      upstream_oid = Native.oid(repo, @upstream)
      return upstream_oid if upstream_oid.is_a?(Err)

      raw_local    = local_oid.value.raw
      raw_upstream = upstream_oid.value.raw
      ahead        = 0_u64
      behind       = 0_u64

      if err = Git.check(LibGit2.graph_ahead_behind(pointerof(ahead), pointerof(behind), repo.handle, pointerof(raw_local), pointerof(raw_upstream)))
        return err
      end

      Ok(Value).new(::Git::AheadBehind.new(ahead, behind))
    end
  end

  class DescendantOf < Command
    describe(:descendant_of, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::ReadOnly)

    def initialize(@commit : String, @ancestor : String)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      commit_oid = Native.oid(repo, @commit)
      return commit_oid if commit_oid.is_a?(Err)

      ancestor_oid = Native.oid(repo, @ancestor)
      return ancestor_oid if ancestor_oid.is_a?(Err)

      raw_commit   = commit_oid.value.raw
      raw_ancestor = ancestor_oid.value.raw

      result = LibGit2.graph_descendant_of(repo.handle, pointerof(raw_commit), pointerof(raw_ancestor))
      if result < 0
        return Err.capture(result)
      end

      Ok(Value).new(result == 1)
    end
  end

  class ReachableFromAny < Command
    describe(:reachable_from_any, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::ReadOnly)

    def initialize(@commit : String, @descendants : Array(String))
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      commit_oid = Native.oid(repo, @commit)
      return commit_oid if commit_oid.is_a?(Err)

      raw_commit      = commit_oid.value.raw
      raw_descendants = Array(LibGit2::Oid).new(@descendants.size)

      @descendants.each do |desc|
        resolved = Native.oid(repo, desc)
        return resolved if resolved.is_a?(Err)
        raw_descendants << resolved.value.raw
      end

      result = LibGit2.graph_reachable_from_any(
        repo.handle,
        pointerof(raw_commit),
        raw_descendants.to_unsafe,
        raw_descendants.size.to_u64
      )
      if result < 0
        return Err.capture(result)
      end

      Ok(Value).new(result == 1)
    end
  end

  class Revwalk < Command
    describe(:revwalk, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::ReadOnly)

    def initialize(@targets : Array(String), @hide : Array(String), @sort : LibGit2::Sort, @limit : Int32?, @first_parent : Bool)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      walker = uninitialized LibGit2::Revwalk
      if err = Git.check(LibGit2.revwalk_new(pointerof(walker), repo.handle))
        return err
      end

      LibGit2.revwalk_sorting(walker, @sort.value)
      LibGit2.revwalk_simplify_first_parent(walker) if @first_parent

      @targets.each do |target|
        if target.includes?("..")
          if err = Git.check(LibGit2.revwalk_push_range(walker, target))
            LibGit2.revwalk_free(walker)
            return err
          end
        elsif target == "HEAD"
          if err = Git.check(LibGit2.revwalk_push_head(walker))
            LibGit2.revwalk_free(walker)
            return err
          end
        elsif target.includes?("*")
          if err = Git.check(LibGit2.revwalk_push_glob(walker, target))
            LibGit2.revwalk_free(walker)
            return err
          end
        else
          resolved = Native.oid(repo, target)
          if resolved.is_a?(Err)
            LibGit2.revwalk_free(walker)
            return resolved
          end
          raw = resolved.value.raw
          if err = Git.check(LibGit2.revwalk_push(walker, pointerof(raw)))
            LibGit2.revwalk_free(walker)
            return err
          end
        end
      end

      @hide.each do |hide_target|
        if hide_target == "HEAD"
          if err = Git.check(LibGit2.revwalk_hide_head(walker))
            LibGit2.revwalk_free(walker)
            return err
          end
        elsif hide_target.includes?("*")
          if err = Git.check(LibGit2.revwalk_hide_glob(walker, hide_target))
            LibGit2.revwalk_free(walker)
            return err
          end
        else
          resolved = Native.oid(repo, hide_target)
          if resolved.is_a?(Err)
            LibGit2.revwalk_free(walker)
            return resolved
          end
          raw = resolved.value.raw
          if err = Git.check(LibGit2.revwalk_hide(walker, pointerof(raw)))
            LibGit2.revwalk_free(walker)
            return err
          end
        end
      end

      oids = [] of Oid
      loop do
        if limit = @limit
          break if oids.size >= limit
        end

        next_oid = uninitialized LibGit2::Oid
        res = LibGit2.revwalk_next(pointerof(next_oid), walker)
        break if res == LibGit2::ErrorCode::ITEROVER.value

        if res != 0
          failure = Err.capture(res)
          LibGit2.revwalk_free(walker)
          return failure
        end

        oids << Oid.new(next_oid)
      end

      LibGit2.revwalk_free(walker)
      Ok(Value).new(oids)
    end
  end

  class WriteCommitGraph < Command
    describe(:write_commit_graph, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::ReadOnly)

    def initialize(@split_strategy : LibGit2::CommitGraphSplitStrategy)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      gitdir = Native.gitdir(repo)
      return gitdir if gitdir.is_a?(Err)
      info_dir = File.join(gitdir.value, "objects", "info")
      Dir.mkdir_p(info_dir)

      opts = uninitialized LibGit2::CommitGraphWriterOptions
      if err = Git.check(LibGit2.commit_graph_writer_options_init(pointerof(opts), 1_u32))
        return err
      end
      opts.split_strategy = @split_strategy

      writer = uninitialized LibGit2::CommitGraphWriter
      if err = Git.check(LibGit2.commit_graph_writer_new(pointerof(writer), info_dir.to_unsafe, pointerof(opts)))
        return err
      end

      walker = uninitialized LibGit2::Revwalk
      if err = Git.check(LibGit2.revwalk_new(pointerof(walker), repo.handle))
        LibGit2.commit_graph_writer_free(writer)
        return err
      end

      if err = Git.check(LibGit2.revwalk_push_glob(walker, "refs/*"))
        LibGit2.revwalk_free(walker)
        LibGit2.commit_graph_writer_free(writer)
        return err
      end

      if err = Git.check(LibGit2.commit_graph_writer_add_revwalk(writer, walker))
        LibGit2.revwalk_free(walker)
        LibGit2.commit_graph_writer_free(writer)
        return err
      end
      LibGit2.revwalk_free(walker)

      result = Git.check(LibGit2.commit_graph_writer_commit(writer))
      LibGit2.commit_graph_writer_free(writer)
      return result if result

      Ok(Value).new(true)
    end
  end
end
