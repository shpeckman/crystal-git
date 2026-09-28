# src/git/commands/inspect.cr
module Git::Commands
  class BlobRead < Command
    describe(:read_blob, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::ReadOnly)

    def initialize(@spec : String)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      blob = Native.blob(repo, @spec)
      return blob if blob.is_a?(Err)
      Ok(Value).new(blob.value)
    end
  end

  class ObjectRead < Command
    describe(:read_object, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::ReadOnly)

    def initialize(@spec : String)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      resolved = Native.oid(repo, @spec)
      return resolved if resolved.is_a?(Err)
      raw = resolved.value.raw

      odb = uninitialized LibGit2::Odb
      if err = Git.check(LibGit2.repository_odb(pointerof(odb), repo.handle))
        return err
      end

      object = uninitialized LibGit2::OdbObject
      result = LibGit2.odb_read(pointerof(object), odb, pointerof(raw))
      if result != 0
        LibGit2.odb_free(odb)
        return Err.capture(result)
      end

      kind = ObjectKind.from_native(LibGit2.odb_object_type(object))
      size = LibGit2.odb_object_size(object)
      data = LibGit2.odb_object_data(object)

      unless kind
        LibGit2.odb_object_free(object)
        LibGit2.odb_free(odb)
        return Err.invalid("unknown object type for #{@spec}")
      end

      bytes = Bytes.new(size.to_i32)
      bytes.copy_from(data.as(UInt8*), size.to_i32) if size > 0

      LibGit2.odb_object_free(object)
      LibGit2.odb_free(odb)
      Ok(Value).new(ObjectData.new(kind, bytes))
    end
  end

  class TreeList < Command
    describe(:tree_list, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::ReadOnly)

    def initialize(@rev : String, @path : String, @recursive : Bool)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      root = Native.tree(repo, @rev)
      return root if root.is_a?(Err)
      tree = root.value

      unless @path.empty?
        entry = uninitialized LibGit2::TreeEntry
        result = LibGit2.tree_entry_bypath(pointerof(entry), tree, @path)
        if result != 0
          LibGit2.tree_free(tree)
          return Err.capture(result)
        end

        unless LibGit2.tree_entry_type(entry) == LibGit2::ObjectType::TREE
          LibGit2.tree_entry_free(entry)
          LibGit2.tree_free(tree)
          return Err.invalid("#{@path} is not a tree in #{@rev}")
        end

        nested = uninitialized LibGit2::Tree
        lookup = LibGit2.tree_lookup(pointerof(nested), repo.handle, LibGit2.tree_entry_id(entry))
        LibGit2.tree_entry_free(entry)
        LibGit2.tree_free(tree)
        if err = Git.check(lookup)
          return err
        end
        tree = nested
      end

      entries = @recursive ? walk(repo, tree) : shallow(repo, tree)
      LibGit2.tree_free(tree)
      Ok(Value).new(entries)
    end

    private def shallow(repo : Repo, tree : LibGit2::Tree) : Array(TreeEntryInfo)
      count   = LibGit2.tree_entrycount(tree)
      entries = Array(TreeEntryInfo).new(count.to_i32)

      count.times do |position|
        entry = LibGit2.tree_entry_byindex(tree, position)
        next if entry.null?
        if info = TreeList.convert(entry, "")
          entries << info
        end
      end

      entries
    end

    private def walk(repo : Repo, tree : LibGit2::Tree) : Array(TreeEntryInfo)
      entries = [] of TreeEntryInfo
      boxed   = Box.box(entries)

      LibGit2.tree_walk(tree, LibGit2::TreewalkMode::PRE, ->(root : LibC::Char*, entry : LibGit2::TreeEntry, payload : Void*) {
        collected = Box(Array(TreeEntryInfo)).unbox(payload)
        prefix    = root.null? ? "" : String.new(root)
        if info = Git::Commands::TreeList.convert(entry, prefix)
          collected << info
        end
        0
      }, boxed)

      entries
    end

    def self.convert(entry : LibGit2::TreeEntry, prefix : String) : TreeEntryInfo?
      name = LibGit2.tree_entry_name(entry)
      return nil if name.null?

      kind = ObjectKind.from_native(LibGit2.tree_entry_type(entry))
      return nil unless kind

      path = prefix.empty? ? String.new(name) : prefix + String.new(name)
      TreeEntryInfo.new(
        path,
        String.new(name),
        kind,
        LibGit2.tree_entry_filemode_raw(entry).value.to_u32,
        Oid.from(LibGit2.tree_entry_id(entry)))
    end
  end
end
