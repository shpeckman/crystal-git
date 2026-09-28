# src/git/commands/blame.cr
module Git::Commands
  class Blame < Command
    describe(:blame, StateSet::All, nil,
      Predicate::None, Predicate::Bare,
      Predicate::None, Predicate::None,
      Reversibility::ReadOnly)

    def initialize(@path : String, @newest : String?, @oldest : String?, @min_line : UInt64?, @max_line : UInt64?)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      opts = uninitialized LibGit2::BlameOptions
      if err = Git.check(LibGit2.blame_options_init(pointerof(opts), 1_u32))
        return err
      end

      if newest = @newest
        oid = Native.oid(repo, newest)
        return oid if oid.is_a?(Err)
        opts.newest_commit = oid.value.raw
      end

      if oldest = @oldest
        oid = Native.oid(repo, oldest)
        return oid if oid.is_a?(Err)
        opts.oldest_commit = oid.value.raw
      end

      opts.min_line = @min_line || 0_u64
      opts.max_line = @max_line || 0_u64

      blame = uninitialized LibGit2::Blame
      if err = Git.check(LibGit2.blame_file(pointerof(blame), repo.handle, @path, pointerof(opts)))
        return err
      end

      count   = LibGit2.blame_hunkcount(blame)
      entries = Array(BlameEntry).new(count.to_i32)

      count.times do |position|
        hunk = LibGit2.blame_hunk_byindex(blame, position)
        next if hunk.null?
        record = hunk.value

        signature = record.final_signature
        author    = signature.null? || signature.value.name.null? ? "" : String.new(signature.value.name)
        email     = signature.null? || signature.value.email.null? ? "" : String.new(signature.value.email)

        orig_path = record.orig_path
        summary   = record.summary
        commit_id = record.final_commit_id

        entries << BlameEntry.new(
          record.final_start_line_number.to_u64,
          record.lines_in_hunk.to_u64,
          Oid.from(pointerof(commit_id)),
          author,
          email,
          summary.null? ? "" : String.new(summary),
          orig_path.null? ? "" : String.new(orig_path),
          record.orig_start_line_number.to_u64,
          record.boundary != 0)
      end

      LibGit2.blame_free(blame)
      Ok(Value).new(entries)
    end
  end
end
