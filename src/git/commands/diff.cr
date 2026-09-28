# src/git/commands/diff.cr
module Git::Commands
  class Diff < Command
    describe(:diff, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::ReadOnly)

    def initialize(@from : String?, @to : String?, @staged : Bool, @paths : Array(String),
                   @output : DiffOutput, @renames : Bool)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      built = build(repo)
      return built if built.is_a?(Err)
      diff = built.value

      if @renames
        find = uninitialized LibGit2::DiffFindOptions
        if err = Git.check(LibGit2.diff_find_options_init(pointerof(find), 1_u32))
          LibGit2.diff_free(diff)
          return err
        end
        find.flags = LibGit2::DiffFindOption::RENAMES.value
        if err = Git.check(LibGit2.diff_find_similar(diff, pointerof(find)))
          LibGit2.diff_free(diff)
          return err
        end
      end

      outcome = case @output
                in DiffOutput::Entries then collect_entries(diff)
                in DiffOutput::Patch   then render_patch(diff)
                in DiffOutput::Stats   then collect_stats(diff)
                in DiffOutput::Files   then collect_files(diff)
                end
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
          new_path.null? ? "" : String.new(new_path),
          record.similarity.to_i32)
      end

      Ok(Value).new(entries)
    end

    private def render_patch(diff : LibGit2::Diff) : Ok(Value) | Err
      buffer = LibGit2::Buf.new
      if err = Git.check(LibGit2.diff_to_buf(pointerof(buffer), diff, LibGit2::DiffFormat::PATCH))
        return err
      end

      patch = buffer.size == 0 ? "" : String.new(buffer.ptr, buffer.size)
      LibGit2.buf_dispose(pointerof(buffer))
      Ok(Value).new(patch)
    end

    private def collect_stats(diff : LibGit2::Diff) : Ok(Value) | Err
      stats = uninitialized LibGit2::DiffStats
      if err = Git.check(LibGit2.diff_get_stats(pointerof(stats), diff))
        return err
      end

      result = DiffStats.new(
        LibGit2.diff_stats_files_changed(stats).to_i32,
        LibGit2.diff_stats_insertions(stats).to_i32,
        LibGit2.diff_stats_deletions(stats).to_i32)
      LibGit2.diff_stats_free(stats)
      Ok(Value).new(result)
    end

    private def collect_files(diff : LibGit2::Diff) : Ok(Value) | Err
      count   = LibGit2.diff_num_deltas(diff)
      patches = Array(FilePatch).new(count.to_i32)

      count.times do |position|
        patch = uninitialized LibGit2::Patch
        if err = Git.check(LibGit2.patch_from_diff(pointerof(patch), diff, position))
          return err
        end

        file_patch = build_file_patch(patch)
        LibGit2.patch_free(patch)
        return file_patch if file_patch.is_a?(Err)
        patches << file_patch.value
      end

      Ok(Value).new(patches)
    end

    private def build_file_patch(patch : LibGit2::Patch) : Ok(FilePatch) | Err
      delta  = LibGit2.patch_get_delta(patch)
      record = delta.value

      hunk_count = LibGit2.patch_num_hunks(patch)
      hunks      = Array(DiffHunkInfo).new(hunk_count.to_i32)

      hunk_count.times do |hunk_idx|
        hunk_out = uninitialized LibGit2::DiffHunk*
        line_count = uninitialized LibC::SizeT
        if err = Git.check(LibGit2.patch_get_hunk(pointerof(hunk_out), pointerof(line_count), patch, hunk_idx))
          return err
        end

        hunk   = hunk_out.value
        header = String.new(hunk.header.to_unsafe, {hunk.header_len, 128}.min).chomp
        lines  = Array(DiffLineInfo).new(line_count.to_i32)

        line_count.times do |line_idx|
          line_out = uninitialized LibGit2::DiffLine*
          if err = Git.check(LibGit2.patch_get_line_in_hunk(pointerof(line_out), patch, hunk_idx, line_idx))
            return err
          end

          line    = line_out.value
          content = String.new(line.content, line.content_len)
          lines << DiffLineInfo.new(
            LineOrigin.from_native(line.origin),
            line.old_lineno < 0 ? nil : line.old_lineno,
            line.new_lineno < 0 ? nil : line.new_lineno,
            content)
        end

        hunks << DiffHunkInfo.new(header, hunk.old_start, hunk.old_lines, hunk.new_start, hunk.new_lines, lines)
      end

      old_path = record.old_file.path
      new_path = record.new_file.path
      Ok(FilePatch).new(FilePatch.new(
        DiffStatus.from_native(record.status),
        old_path.null? ? "" : String.new(old_path),
        new_path.null? ? "" : String.new(new_path),
        record.similarity.to_i32,
        hunks))
    end
  end
end
