# src/git/commands/mailmap.cr
module Git::Commands
  class MailmapResolve < Command
    describe(:mailmap_resolve, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::ReadOnly)

    def initialize(@name : String, @email : String)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      mailmap = uninitialized LibGit2::Mailmap
      result = LibGit2.mailmap_from_repository(pointerof(mailmap), repo.handle)
      if result == LibGit2::ErrorCode::ENOTFOUND.value
        return Ok(Value).new(Identity.new(@name, @email))
      end
      if err = Git.check(result)
        return err
      end

      name = uninitialized LibC::Char*
      email = uninitialized LibC::Char*
      rc = LibGit2.mailmap_resolve(pointerof(name), pointerof(email), mailmap, @name, @email)

      if err = Git.check(rc)
        LibGit2.mailmap_free(mailmap)
        return err
      end

      identity = Identity.new(
        name.null? ? @name : String.new(name),
        email.null? ? @email : String.new(email))
      LibGit2.mailmap_free(mailmap)

      Ok(Value).new(identity)
    end
  end
end
