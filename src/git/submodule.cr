# src/git/submodule.cr
module Git
  module Submodules
    def self.names(repo : Repo) : Ok(Array(String)) | Err
      collected = [] of String
      boxed     = Box.box(collected)

      result = LibGit2.submodule_foreach(repo.handle, ->(submodule : LibGit2::Submodule, name : LibC::Char*, payload : Void*) {
        list = Box(Array(String)).unbox(payload)
        list << String.new(name) unless name.null?
        0
      }, boxed)

      if err = Git.check(result)
        return err
      end
      Ok(Array(String)).new(collected)
    end

    def self.entry(repo : Repo, name : String) : Ok(SubmoduleEntry) | Err
      submodule = uninitialized LibGit2::Submodule
      if err = Git.check(LibGit2.submodule_lookup(pointerof(submodule), repo.handle, name))
        return err
      end

      path   = Native.text(LibGit2.submodule_path(submodule)) || name
      url    = Native.text(LibGit2.submodule_url(submodule))
      branch = Native.text(LibGit2.submodule_branch(submodule))

      head    = LibGit2.submodule_head_id(submodule)
      indexed = LibGit2.submodule_index_id(submodule)
      workdir = LibGit2.submodule_wd_id(submodule)

      head_oid    = head.null? ? nil : Oid.from(head)
      indexed_oid = indexed.null? ? nil : Oid.from(indexed)
      workdir_oid = workdir.null? ? nil : Oid.from(workdir)

      status = uninitialized LibC::UInt
      if err = Git.check(LibGit2.submodule_status(pointerof(status), repo.handle, name, LibGit2::SubmoduleIgnoreType::UNSPECIFIED))
        LibGit2.submodule_free(submodule)
        return err
      end

      LibGit2.submodule_free(submodule)

      Ok(SubmoduleEntry).new(SubmoduleEntry.new(
        name, path, url, branch,
        head_oid, indexed_oid, workdir_oid,
        status.to_u32))
    end
  end

  struct SubmoduleEntry
    getter name        : String
    getter path        : String
    getter url         : String?
    getter branch      : String?
    getter head_oid    : Oid?
    getter index_oid   : Oid?
    getter workdir_oid : Oid?
    getter status      : UInt32

    def initialize(@name : String, @path : String, @url : String?, @branch : String?,
                   @head_oid : Oid?, @index_oid : Oid?, @workdir_oid : Oid?, @status : UInt32)
    end

    private def flag?(bit : LibGit2::SubmoduleStatus) : Bool
      (@status & bit.value) != 0
    end

    def in_head? : Bool
      flag?(LibGit2::SubmoduleStatus::IN_HEAD)
    end

    def in_index? : Bool
      flag?(LibGit2::SubmoduleStatus::IN_INDEX)
    end

    def in_config? : Bool
      flag?(LibGit2::SubmoduleStatus::IN_CONFIG)
    end

    def in_workdir? : Bool
      flag?(LibGit2::SubmoduleStatus::IN_WD)
    end

    def initialized? : Bool
      in_workdir? && !flag?(LibGit2::SubmoduleStatus::WD_UNINITIALIZED)
    end

    def added? : Bool
      flag?(LibGit2::SubmoduleStatus::INDEX_ADDED) || flag?(LibGit2::SubmoduleStatus::WD_ADDED)
    end

    def deleted? : Bool
      flag?(LibGit2::SubmoduleStatus::INDEX_DELETED) || flag?(LibGit2::SubmoduleStatus::WD_DELETED)
    end

    def modified? : Bool
      flag?(LibGit2::SubmoduleStatus::INDEX_MODIFIED) ||
        flag?(LibGit2::SubmoduleStatus::WD_MODIFIED) ||
        flag?(LibGit2::SubmoduleStatus::WD_INDEX_MODIFIED)
    end

    def dirty? : Bool
      modified? || added? || deleted?
    end

    def ==(other : SubmoduleEntry) : Bool
      @name == other.name && @path == other.path && @status == other.status
    end

    def to_s(io : IO) : Nil
      io << @name << ' ' << @path
      io << " (uninitialized)" if in_workdir? && !initialized?
    end
  end
end
