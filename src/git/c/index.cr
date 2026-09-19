# src/git/c/index.cr
@[Link("git2")]
lib LibGit2
  # ============================================================================
  # INDEX (git2/index.h)
  # ============================================================================

  struct IndexTime
    seconds     : LibC::Int32
    nanoseconds : LibC::UInt32
  end

  struct IndexEntry
    ctime          : IndexTime
    mtime          : IndexTime
    dev            : LibC::UInt32
    ino            : LibC::UInt32
    mode           : LibC::UInt32
    uid            : LibC::UInt32
    gid            : LibC::UInt32
    file_size      : LibC::UInt32
    id             : Oid
    flags          : LibC::UInt16
    flags_extended : LibC::UInt16
    path           : LibC::Char*
  end

  enum IndexEntryFlag
    EXTENDED = 16384 # 0x4000
    VALID    = 32768 # 0x8000
  end

  enum IndexEntryExtendedFlag
    INTENT_TO_ADD =  8192
    SKIP_WORKTREE = 16384
    UPTODATE      =     4
  end

  enum IndexCapability
    IGNORE_CASE =  1
    NO_FILEMODE =  2
    NO_SYMLINKS =  4
    FROM_OWNER  = -1
  end

  enum IndexAddOption
    DEFAULT                = 0
    FORCE                  = 1
    DISABLE_PATHSPEC_MATCH = 2
    CHECK_PATHSPEC         = 4
  end

  enum IndexStage
    ANY      = -1
    NORMAL   =  0
    ANCESTOR =  1
    OURS     =  2
    THEIRS   =  3
  end

  struct IndexOptions
    version  : LibC::UInt
    oid_type : OidType
  end

  alias IndexMatchedPathCb = (LibC::Char*, LibC::Char*, Void* -> LibC::Int)

  fun index_options_init = git_index_options_init(opts : IndexOptions*, version : LibC::UInt) : LibC::Int
  fun index_open = git_index_open(index_out : Index*, index_path : LibC::Char*) : LibC::Int
  fun index_open_ext = git_index_open_ext(index_out : Index*, index_path : LibC::Char*, opts : IndexOptions*) : LibC::Int
  fun index_new = git_index_new(index_out : Index*) : LibC::Int
  fun index_new_ext = git_index_new_ext(index_out : Index*, opts : IndexOptions*) : LibC::Int
  fun index_free = git_index_free(index : Index)
  fun index_owner = git_index_owner(index : Index) : Repository
  fun index_caps = git_index_caps(index : Index) : LibC::Int
  fun index_set_caps = git_index_set_caps(index : Index, caps : LibC::Int) : LibC::Int
  fun index_version = git_index_version(index : Index) : LibC::UInt
  fun index_set_version = git_index_set_version(index : Index, version : LibC::UInt) : LibC::Int
  fun index_read = git_index_read(index : Index, force : LibC::Int) : LibC::Int
  fun index_write = git_index_write(index : Index) : LibC::Int
  fun index_path = git_index_path(index : Index) : LibC::Char*
  fun index_read_tree = git_index_read_tree(index : Index, tree : Tree) : LibC::Int
  fun index_write_tree = git_index_write_tree(out_oid : Oid*, index : Index) : LibC::Int
  fun index_write_tree_to = git_index_write_tree_to(out_oid : Oid*, index : Index, repo : Repository) : LibC::Int
  fun index_entrycount = git_index_entrycount(index : Index) : LibC::SizeT
  fun index_clear = git_index_clear(index : Index) : LibC::Int
  fun index_get_byindex = git_index_get_byindex(index : Index, n : LibC::SizeT) : IndexEntry*
  fun index_get_bypath = git_index_get_bypath(index : Index, path : LibC::Char*, stage : LibC::Int) : IndexEntry*
  fun index_remove = git_index_remove(index : Index, path : LibC::Char*, stage : LibC::Int) : LibC::Int
  fun index_remove_directory = git_index_remove_directory(index : Index, dir : LibC::Char*, stage : LibC::Int) : LibC::Int
  fun index_add = git_index_add(index : Index, source_entry : IndexEntry*) : LibC::Int
  fun index_entry_stage = git_index_entry_stage(entry : IndexEntry*) : LibC::Int
  fun index_entry_is_conflict = git_index_entry_is_conflict(entry : IndexEntry*) : LibC::Int
  fun index_iterator_new = git_index_iterator_new(iterator_out : IndexIterator*, index : Index) : LibC::Int
  fun index_iterator_next = git_index_iterator_next(out_entry : IndexEntry**, iterator : IndexIterator) : LibC::Int
  fun index_iterator_free = git_index_iterator_free(iterator : IndexIterator)
  fun index_add_bypath = git_index_add_bypath(index : Index, path : LibC::Char*) : LibC::Int
  fun index_add_from_buffer = git_index_add_from_buffer(index : Index, entry : IndexEntry*, buffer : Void*, len : LibC::SizeT) : LibC::Int
  fun index_remove_bypath = git_index_remove_bypath(index : Index, path : LibC::Char*) : LibC::Int
  fun index_add_all = git_index_add_all(index : Index, pathspec : Strarray*, flags : LibC::UInt, callback : IndexMatchedPathCb, payload : Void*) : LibC::Int
  fun index_remove_all = git_index_remove_all(index : Index, pathspec : Strarray*, callback : IndexMatchedPathCb, payload : Void*) : LibC::Int
  fun index_update_all = git_index_update_all(index : Index, pathspec : Strarray*, callback : IndexMatchedPathCb, payload : Void*) : LibC::Int
  fun index_find = git_index_find(at_pos : LibC::SizeT*, index : Index, path : LibC::Char*) : LibC::Int
  fun index_find_prefix = git_index_find_prefix(at_pos : LibC::SizeT*, index : Index, prefix : LibC::Char*) : LibC::Int
  fun index_conflict_add = git_index_conflict_add(index : Index, ancestor_entry : IndexEntry*, our_entry : IndexEntry*, their_entry : IndexEntry*) : LibC::Int
  fun index_conflict_get = git_index_conflict_get(ancestor_out : IndexEntry**, our_out : IndexEntry**, their_out : IndexEntry**, index : Index, path : LibC::Char*) : LibC::Int
  fun index_conflict_remove = git_index_conflict_remove(index : Index, path : LibC::Char*) : LibC::Int
  fun index_conflict_cleanup = git_index_conflict_cleanup(index : Index) : LibC::Int
  fun index_has_conflicts = git_index_has_conflicts(index : Index) : LibC::Int
  fun index_conflict_iterator_new = git_index_conflict_iterator_new(iterator_out : IndexConflictIterator*, index : Index) : LibC::Int
  fun index_conflict_next = git_index_conflict_next(ancestor_out : IndexEntry**, our_out : IndexEntry**, their_out : IndexEntry**, iterator : IndexConflictIterator) : LibC::Int
  fun index_conflict_iterator_free = git_index_conflict_iterator_free(iterator : IndexConflictIterator)
end
