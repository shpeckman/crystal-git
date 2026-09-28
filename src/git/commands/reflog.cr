# src/git/commands/reflog.cr
module Git::Commands
  class Reflog < Command
    describe(:reflog, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::ReadOnly)

    def initialize(@refname : String)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      gitdir = Native.gitdir(repo)
      return gitdir if gitdir.is_a?(Err)

      unless File.exists?(File.join(gitdir.value, "logs", @refname))
        return Err.invalid("#{@refname} has no reflog")
      end

      log = uninitialized LibGit2::Reflog
      if err = Git.check(LibGit2.reflog_read(pointerof(log), repo.handle, @refname))
        return err
      end

      count   = LibGit2.reflog_entrycount(log)
      entries = Array(ReflogEntry).new(count.to_i32)

      count.times do |position|
        entry = LibGit2.reflog_entry_byindex(log, position)
        next if entry.null?

        old_id    = LibGit2.reflog_entry_id_old(entry)
        new_id    = LibGit2.reflog_entry_id_new(entry)
        committer = LibGit2.reflog_entry_committer(entry)
        message   = LibGit2.reflog_entry_message(entry)

        name  = committer.null? || committer.value.name.null? ? "" : String.new(committer.value.name)
        email = committer.null? || committer.value.email.null? ? "" : String.new(committer.value.email)

        entries << ReflogEntry.new(
          old_id.null? ? Oid.zero : Oid.from(old_id),
          new_id.null? ? Oid.zero : Oid.from(new_id),
          name,
          email,
          message.null? ? "" : String.new(message).chomp)
      end

      LibGit2.reflog_free(log)
      Ok(Value).new(entries)
    end
  end
end
