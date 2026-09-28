# src/git/commands/notes.cr
module Git::Commands
  class AddNote < Command
    describe(:note_add, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::RefOnly)

    def initialize(@target : String, @message : String, @ref : String?, @force : Bool)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      oid = Native.oid(repo, @target)
      return oid if oid.is_a?(Err)
      raw = oid.value.raw

      signature = repo.signature
      return signature if signature.is_a?(Err)

      prior = Notes.read_message(repo, @ref, pointerof(raw))
      return prior if prior.is_a?(Err)

      created = uninitialized LibGit2::Oid
      result = LibGit2.note_create(pointerof(created), repo.handle, Native.pointer(@ref),
        signature.value, signature.value, pointerof(raw), @message, @force ? 1 : 0)
      if err = Git.check(result)
        return err
      end

      undo << Undo::NoteSet.new(@ref, oid.value, prior.value)
      Ok(Value).new(Oid.new(created))
    end
  end

  class RemoveNote < Command
    describe(:note_remove, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::RefOnly)

    def initialize(@target : String, @ref : String?)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      oid = Native.oid(repo, @target)
      return oid if oid.is_a?(Err)
      raw = oid.value.raw

      signature = repo.signature
      return signature if signature.is_a?(Err)

      prior = Notes.read_message(repo, @ref, pointerof(raw))
      return prior if prior.is_a?(Err)

      if err = Git.check(LibGit2.note_remove(repo.handle, Native.pointer(@ref), signature.value, signature.value, pointerof(raw)))
        return err
      end

      undo << Undo::NoteSet.new(@ref, oid.value, prior.value)
      Ok(Value).new(@target)
    end
  end

  class ShowNote < Command
    describe(:note_show, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::ReadOnly)

    def initialize(@target : String, @ref : String?)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      oid = Native.oid(repo, @target)
      return oid if oid.is_a?(Err)
      raw = oid.value.raw

      note = uninitialized LibGit2::Note
      result = LibGit2.note_read(pointerof(note), repo.handle, Native.pointer(@ref), pointerof(raw))
      if result == LibGit2::ErrorCode::ENOTFOUND.value
        return Ok(Value).new(nil)
      end
      if err = Git.check(result)
        return err
      end

      blob    = LibGit2.note_id(note)
      message = Native.text(LibGit2.note_message(note)) || ""
      author  = LibGit2.note_author(note)
      name    = author.null? || author.value.name.null? ? "" : String.new(author.value.name)
      email   = author.null? || author.value.email.null? ? "" : String.new(author.value.email)
      built   = Note.new(oid.value, blob.null? ? Oid.zero : Oid.from(blob), message.chomp, name, email)

      LibGit2.note_free(note)
      Ok(Value).new(built)
    end
  end

  class ListNotes < Command
    describe(:note_list, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::ReadOnly)

    def initialize(@ref : String?)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      entries = [] of NoteEntry
      boxed   = Box.box(entries)

      result = LibGit2.note_foreach(repo.handle, Native.pointer(@ref), ->(blob : LibGit2::Oid*, annotated : LibGit2::Oid*, payload : Void*) {
        list = Box(Array(NoteEntry)).unbox(payload)
        list << NoteEntry.new(Oid.from(annotated), Oid.from(blob))
        0
      }, boxed)

      if result == LibGit2::ErrorCode::ENOTFOUND.value
        return Ok(Value).new(entries)
      end
      if err = Git.check(result)
        return err
      end
      Ok(Value).new(entries)
    end
  end

  module Notes
    def self.read_message(repo : Repo, ref : String?, oid : LibGit2::Oid*) : Ok(String?) | Err
      note = uninitialized LibGit2::Note
      result = LibGit2.note_read(pointerof(note), repo.handle, Native.pointer(ref), oid)
      if result == LibGit2::ErrorCode::ENOTFOUND.value
        return Ok(String?).new(nil)
      end
      if err = Git.check(result)
        return err
      end

      message = Native.text(LibGit2.note_message(note))
      LibGit2.note_free(note)
      Ok(String?).new(message.try(&.chomp))
    end
  end
end
