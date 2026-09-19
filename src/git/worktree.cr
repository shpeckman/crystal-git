# src/git/worktree.cr
module Git
  struct WorktreeEntry
    getter path        : String
    getter bytes       : Bytes?
    getter permissions : File::Permissions

    def initialize(@path : String, @bytes : Bytes?, @permissions : File::Permissions)
    end

    def absent? : Bool
      @bytes.nil?
    end
  end

  module Worktree
    CANDIDATE_FLAGS = LibGit2::StatusOpt::INCLUDE_UNTRACKED.value |
                      LibGit2::StatusOpt::RECURSE_UNTRACKED_DIRS.value |
                      LibGit2::StatusOpt::INCLUDE_UNREADABLE.value

    def self.candidates(repo : Repo) : Ok(Array(String)) | Err
      opts = uninitialized LibGit2::StatusOptions
      if err = Git.check(LibGit2.status_options_init(pointerof(opts), 1_u32))
        return err
      end
      opts.show = LibGit2::StatusShow::INDEX_AND_WORKDIR
      opts.flags = CANDIDATE_FLAGS

      list = uninitialized LibGit2::StatusList
      if err = Git.check(LibGit2.status_list_new(pointerof(list), repo.handle, pointerof(opts)))
        return err
      end

      paths = [] of String
      seen  = Set(String).new

      LibGit2.status_list_entrycount(list).times do |position|
        entry = LibGit2.status_byindex(list, position)
        next if entry.null?

        {entry.value.head_to_index, entry.value.index_to_workdir}.each do |delta|
          next if delta.null?
          {delta.value.old_file.path, delta.value.new_file.path}.each do |raw|
            text = Native.text(raw)
            next unless text
            next if seen.includes?(text)
            seen << text
            paths << text
          end
        end
      end

      LibGit2.status_list_free(list)
      Ok(Array(String)).new(paths)
    end

    def self.capture(repo : Repo, paths : Array(String)) : Ok(Array(WorktreeEntry)) | Err
      workdir = Native.workdir(repo)
      return workdir if workdir.is_a?(Err)
      root = workdir.value

      entries = Array(WorktreeEntry).new(paths.size)
      paths.each do |path|
        full = File.join(root, path)
        if File.file?(full)
          entries << WorktreeEntry.new(path, Native.read_bytes(full), File.info(full).permissions)
        else
          entries << WorktreeEntry.new(path, nil, File::Permissions.new(0))
        end
      end

      Ok(Array(WorktreeEntry)).new(entries)
    end

    def self.restore(repo : Repo, entries : Array(WorktreeEntry)) : Err?
      workdir = Native.workdir(repo)
      return workdir if workdir.is_a?(Err)
      root = workdir.value

      known = Set(String).new
      entries.each { |entry| known << entry.path }

      current = candidates(repo)
      return current if current.is_a?(Err)

      current.value.each do |path|
        next if known.includes?(path)
        Native.discard(File.join(root, path))
      end

      entries.each do |entry|
        full = File.join(root, entry.path)
        if bytes = entry.bytes
          Native.write_bytes(full, bytes)
          File.chmod(full, entry.permissions)
        else
          Native.discard(full)
        end
      end

      nil
    end
  end
end
