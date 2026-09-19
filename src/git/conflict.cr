# src/git/conflict.cr
module Git
  enum Resolution
    Ours
    Theirs
    Union
  end

  struct ConflictEntry
    getter path     : String
    getter ancestor : Oid?
    getter ours     : Oid?
    getter theirs   : Oid?

    def initialize(@path : String, @ancestor : Oid?, @ours : Oid?, @theirs : Oid?)
    end

    def added_by_both? : Bool
      @ancestor.nil?
    end

    def deleted_by_us? : Bool
      @ours.nil?
    end

    def deleted_by_them? : Bool
      @theirs.nil?
    end

    def to_s(io : IO) : Nil
      io << path
    end
  end

  module Conflict
    private struct Resolved
      getter oid   : Oid
      getter mode  : UInt32
      getter bytes : Bytes

      def initialize(@oid : Oid, @mode : UInt32, @bytes : Bytes)
      end
    end

    def self.list(repo : Repo) : Ok(Array(ConflictEntry)) | Err
      index = repo.index
      return index if index.is_a?(Err)

      iterator = uninitialized LibGit2::IndexConflictIterator
      if err = Git.check(LibGit2.index_conflict_iterator_new(pointerof(iterator), index.value))
        return err
      end

      entries = [] of ConflictEntry
      loop do
        ancestor = uninitialized LibGit2::IndexEntry*
        ours = uninitialized LibGit2::IndexEntry*
        theirs = uninitialized LibGit2::IndexEntry*

        result = LibGit2.index_conflict_next(pointerof(ancestor), pointerof(ours), pointerof(theirs), iterator)
        break if result == LibGit2::ErrorCode::ITEROVER.value

        if result != 0
          failure = Err.capture(result)
          LibGit2.index_conflict_iterator_free(iterator)
          return failure
        end

        path = path_of(ancestor, ours, theirs)
        next unless path

        entries << ConflictEntry.new(path, oid_of(ancestor), oid_of(ours), oid_of(theirs))
      end

      LibGit2.index_conflict_iterator_free(iterator)
      Ok(Array(ConflictEntry)).new(entries)
    end

    def self.paths(repo : Repo) : Ok(Array(String)) | Err
      result = list(repo)
      return result if result.is_a?(Err)
      Ok(Array(String)).new(result.value.map(&.path))
    end

    def self.resolve(repo : Repo, path : String, resolution : Resolution) : Err?
      index = repo.index
      return index if index.is_a?(Err)
      handle = index.value

      ancestor = uninitialized LibGit2::IndexEntry*
      ours = uninitialized LibGit2::IndexEntry*
      theirs = uninitialized LibGit2::IndexEntry*

      if err = Git.check(LibGit2.index_conflict_get(pointerof(ancestor), pointerof(ours), pointerof(theirs), handle, path))
        return err
      end

      built = build(repo, ancestor, ours, theirs, resolution)
      return built if built.is_a?(Err)
      resolved = built.value

      if err = Git.check(LibGit2.index_conflict_remove(handle, path))
        return err
      end

      if resolved
        entry = LibGit2::IndexEntry.new
        entry.path = path.to_unsafe
        entry.id = resolved.oid.raw
        entry.mode = resolved.mode
        entry.flags = 0_u16
        entry.flags_extended = 0_u16

        if err = Git.check(LibGit2.index_add(handle, pointerof(entry)))
          return err
        end
      end

      if err = Git.check(LibGit2.index_write(handle))
        return err
      end

      workdir = Native.text(LibGit2.repository_workdir(repo.handle))
      return nil unless workdir

      full = File.join(workdir, path)
      if resolved
        Dir.mkdir_p(File.dirname(full))
        File.write(full, resolved.bytes)
      elsif File.exists?(full)
        File.delete(full)
      end

      nil
    end

    private def self.build(repo : Repo, ancestor : LibGit2::IndexEntry*, ours : LibGit2::IndexEntry*,
                           theirs : LibGit2::IndexEntry*, resolution : Resolution) : Ok(Resolved?) | Err
      case resolution
      when .ours?
        side(repo, ours)
      when .theirs?
        side(repo, theirs)
      else
        union(repo, ancestor, ours, theirs)
      end
    end

    private def self.side(repo : Repo, entry : LibGit2::IndexEntry*) : Ok(Resolved?) | Err
      return Ok(Resolved?).new(nil) if entry.null?

      oid  = Oid.new(entry.value.id)
      mode = entry.value.mode

      bytes = blob_bytes(repo, oid)
      return bytes if bytes.is_a?(Err)

      Ok(Resolved?).new(Resolved.new(oid, mode, bytes.value))
    end

    private def self.union(repo : Repo, ancestor : LibGit2::IndexEntry*, ours : LibGit2::IndexEntry*,
                           theirs : LibGit2::IndexEntry*) : Ok(Resolved?) | Err
      opts = uninitialized LibGit2::MergeFileOptions
      if err = Git.check(LibGit2.merge_file_options_init(pointerof(opts), 1_u32))
        return err
      end
      opts.favor = LibGit2::MergeFileFavor::UNION

      result = uninitialized LibGit2::MergeFileResult
      if err = Git.check(LibGit2.merge_file_from_index(pointerof(result), repo.handle, ancestor, ours, theirs, pointerof(opts)))
        return err
      end

      bytes = if result.ptr.null? || result.len == 0
                Bytes.new(0)
              else
                Bytes.new(result.ptr.as(UInt8*), result.len.to_i32).dup
              end
      mode = result.mode
      LibGit2.merge_file_result_free(pointerof(result))

      mode = LibGit2::FilemodeType::BLOB.value.to_u32 if mode == 0

      oid = uninitialized LibGit2::Oid
      if err = Git.check(LibGit2.blob_create_from_buffer(pointerof(oid), repo.handle, bytes.to_unsafe.as(Pointer(Void)), bytes.size.to_u64))
        return err
      end

      Ok(Resolved?).new(Resolved.new(Oid.new(oid), mode, bytes))
    end

    private def self.blob_bytes(repo : Repo, oid : Oid) : Ok(Bytes) | Err
      raw = oid.raw
      blob = uninitialized LibGit2::Blob
      if err = Git.check(LibGit2.blob_lookup(pointerof(blob), repo.handle, pointerof(raw)))
        return err
      end

      size  = LibGit2.blob_rawsize(blob)
      data  = LibGit2.blob_rawcontent(blob)
      bytes = data.null? || size == 0 ? Bytes.new(0) : Bytes.new(data.as(UInt8*), size.to_i32).dup
      LibGit2.blob_free(blob)

      Ok(Bytes).new(bytes)
    end

    private def self.path_of(ancestor : LibGit2::IndexEntry*, ours : LibGit2::IndexEntry*, theirs : LibGit2::IndexEntry*) : String?
      {ours, theirs, ancestor}.each do |entry|
        next if entry.null?
        text = Native.text(entry.value.path)
        return text if text
      end
      nil
    end

    private def self.oid_of(entry : LibGit2::IndexEntry*) : Oid?
      entry.null? ? nil : Oid.new(entry.value.id)
    end
  end
end
