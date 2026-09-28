# src/git/commands/diff.cr
module Git::Commands
  class Diff < Command
    describe(:diff, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::ReadOnly)

    def initialize(@from : String?, @to : String?, @staged : Bool, @paths : Array(String), @patch : Bool)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      built = build(repo)
      return built if built.is_a?(Err)
      diff = built.value

      outcome = @patch ? render_patch(diff) : collect_entries(diff)
      LibGit2.diff_free(diff)
      outcome
    end

    private def build(repo : Repo) : Ok(LibGit2::Diff) | Err
      opts = uninitialized LibGit2::DiffOptions
      if err = Git.check(LibGit2.diff_options_init(pointerof(opts), 1_u32))
        return err
      end

      unless @paths.empty?
        pointers = @paths.map(&.to_unsafe)
        pathspec = LibGit2::Strarray.new
        pathspec.strings = pointers.to_unsafe
        pathspec.count = @paths.size.to_u64
        opts.pathspec = pathspec
      end

      diff = uninitialized LibGit2::Diff
      result = run(repo, pointerof(diff), pointerof(opts))
      return result if result.is_a?(Err)
      Ok(LibGit2::Diff).new(diff)
    end

    private def run(repo : Repo, diff : LibGit2::Diff*, opts : LibGit2::DiffOptions*) : Err?
      if from = @from
        old_tree = Native.tree(repo, from)
        return old_tree if old_tree.is_a?(Err)

        if to = @to
          new_tree = Native.tree(repo, to)
          if new_tree.is_a?(Err)
            LibGit2.tree_free(old_tree.value)
            return new_tree
          end
          result = LibGit2.diff_tree_to_tree(diff, repo.handle, old_tree.value, new_tree.value, opts)
          LibGit2.tree_free(old_tree.value)
          LibGit2.tree_free(new_tree.value)
          Git.check(result)
        else
          result = LibGit2.diff_tree_to_workdir_with_index(diff, repo.handle, old_tree.value, opts)
          LibGit2.tree_free(old_tree.value)
          Git.check(result)
        end
      elsif @staged
        index = repo.index
        return index if index.is_a?(Err)

        if LibGit2.repository_head_unborn(repo.handle) == 1
          Git.check(LibGit2.diff_tree_to_index(diff, repo.handle, Native.null_tree, index.value, opts))
        else
          head_tree = Native.tree(repo, "HEAD")
          return head_tree if head_tree.is_a?(Err)
          result = LibGit2.diff_tree_to_index(diff, repo.handle, head_tree.value, index.value, opts)
          LibGit2.tree_free(head_tree.value)
          Git.check(result)
        end
      else
        index = repo.index
        return index if index.is_a?(Err)
        Git.check(LibGit2.diff_index_to_workdir(diff, repo.handle, index.value, opts))
      end
    end

    private def collect_entries(diff : LibGit2::Diff) : Ok(Value) | Err
      count   = LibGit2.diff_num_deltas(diff)
      entries = Array(DiffEntry).new(count.to_i32)

      count.times do |position|
        delta = LibGit2.diff_get_delta(diff, position)
        next if delta.null?

        record   = delta.value
        old_path = record.old_file.path
        new_path = record.new_file.path
        entries << DiffEntry.new(
          DiffStatus.from_native(record.status),
          old_path.null? ? "" : String.new(old_path),
          new_path.null? ? "" : String.new(new_path))
      end

      Ok(Value).new(entries)
    end

    private def render_patch(diff : LibGit2::Diff) : Ok(Value) | Err
      buffer = uninitialized LibGit2::Buf
      if err = Git.check(LibGit2.diff_to_buf(pointerof(buffer), diff, LibGit2::DiffFormat::PATCH))
        return err
      end

      patch = buffer.size == 0 ? "" : String.new(buffer.ptr, buffer.size)
      LibGit2.buf_dispose(pointerof(buffer))
      Ok(Value).new(patch)
    end
  end
end
