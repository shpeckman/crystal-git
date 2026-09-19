# src/git/stash.cr
module Git
  struct StashEntry
    getter position : Int32
    getter message  : String
    getter oid      : Oid

    def initialize(@position : Int32, @message : String, @oid : Oid)
    end

    def to_s(io : IO) : Nil
      io << "stash@{" << position << "} " << message
    end
  end

  module Stash
    class Locator
      getter target  : Oid
      property found : Int32?

      def initialize(@target : Oid)
      end
    end

    def self.locate(repo : Repo, oid : Oid) : Int32?
      locator = Locator.new(oid)
      boxed   = Box.box(locator)

      LibGit2.stash_foreach(repo.handle, ->(position : LibC::SizeT, message : LibC::Char*, entry : LibGit2::Oid*, payload : Void*) {
        found = Box(Locator).unbox(payload)
        if found.found.nil? && Oid.from(entry) == found.target
          found.found = position.to_i32
        end
        0
      }, boxed)

      locator.found
    end

    def self.list(repo : Repo) : Ok(Array(StashEntry)) | Err
      entries = [] of StashEntry
      boxed   = Box.box(entries)

      result = LibGit2.stash_foreach(repo.handle, ->(position : LibC::SizeT, message : LibC::Char*, entry : LibGit2::Oid*, payload : Void*) {
        collected = Box(Array(StashEntry)).unbox(payload)
        text      = message.null? ? "" : String.new(message)
        collected << StashEntry.new(position.to_i32, text, Oid.from(entry))
        0
      }, boxed)

      if err = Git.check(result)
        return err
      end
      Ok(Array(StashEntry)).new(entries)
    end
  end
end
