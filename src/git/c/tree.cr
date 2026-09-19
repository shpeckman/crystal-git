# src/git/c/tree.cr
@[Link("git2")]
lib LibGit2
  # ============================================================================
  # TREES (git2/tree.h)
  # ============================================================================

  enum TreewalkMode
    PRE  = 0
    POST = 1
  end

  enum TreeUpdateType
    UPSERT = 0
    REMOVE = 1
  end

  struct TreeUpdate
    action   : TreeUpdateType
    id       : Oid
    filemode : FilemodeType
    path     : LibC::Char*
  end

  alias TreebuilderFilterCb = (TreeEntry, Void* -> LibC::Int)
  alias TreewalkCb = (LibC::Char*, TreeEntry, Void* -> LibC::Int)

  fun tree_lookup = git_tree_lookup(out_tree : Tree*, repo : Repository, id : Oid*) : LibC::Int
  fun tree_lookup_prefix = git_tree_lookup_prefix(out_tree : Tree*, repo : Repository, id : Oid*, len : LibC::SizeT) : LibC::Int
  fun tree_free = git_tree_free(tree : Tree)
  fun tree_id = git_tree_id(tree : Tree) : Oid*
  fun tree_owner = git_tree_owner(tree : Tree) : Repository
  fun tree_entrycount = git_tree_entrycount(tree : Tree) : LibC::SizeT
  fun tree_entry_byname = git_tree_entry_byname(tree : Tree, filename : LibC::Char*) : TreeEntry
  fun tree_entry_byindex = git_tree_entry_byindex(tree : Tree, idx : LibC::SizeT) : TreeEntry
  fun tree_entry_byid = git_tree_entry_byid(tree : Tree, id : Oid*) : TreeEntry
  fun tree_entry_bypath = git_tree_entry_bypath(out_entry : TreeEntry*, root : Tree, path : LibC::Char*) : LibC::Int
  fun tree_entry_dup = git_tree_entry_dup(dest : TreeEntry*, source : TreeEntry) : LibC::Int
  fun tree_entry_free = git_tree_entry_free(entry : TreeEntry)
  fun tree_entry_name = git_tree_entry_name(entry : TreeEntry) : LibC::Char*
  fun tree_entry_id = git_tree_entry_id(entry : TreeEntry) : Oid*
  fun tree_entry_type = git_tree_entry_type(entry : TreeEntry) : ObjectType
  fun tree_entry_filemode = git_tree_entry_filemode(entry : TreeEntry) : FilemodeType
  fun tree_entry_filemode_raw = git_tree_entry_filemode_raw(entry : TreeEntry) : FilemodeType
  fun tree_entry_cmp = git_tree_entry_cmp(e1 : TreeEntry, e2 : TreeEntry) : LibC::Int
  fun tree_entry_to_object = git_tree_entry_to_object(object_out : Object*, repo : Repository, entry : TreeEntry) : LibC::Int

  fun treebuilder_new = git_treebuilder_new(out_bld : Treebuilder*, repo : Repository, source : Tree) : LibC::Int
  fun treebuilder_clear = git_treebuilder_clear(bld : Treebuilder) : LibC::Int
  fun treebuilder_entrycount = git_treebuilder_entrycount(bld : Treebuilder) : LibC::SizeT
  fun treebuilder_free = git_treebuilder_free(bld : Treebuilder)
  fun treebuilder_get = git_treebuilder_get(bld : Treebuilder, filename : LibC::Char*) : TreeEntry
  fun treebuilder_insert = git_treebuilder_insert(out_entry : TreeEntry*, bld : Treebuilder, filename : LibC::Char*, id : Oid*, filemode : FilemodeType) : LibC::Int
  fun treebuilder_remove = git_treebuilder_remove(bld : Treebuilder, filename : LibC::Char*) : LibC::Int
  fun treebuilder_filter = git_treebuilder_filter(bld : Treebuilder, filter : TreebuilderFilterCb, payload : Void*) : LibC::Int
  fun treebuilder_write = git_treebuilder_write(id : Oid*, bld : Treebuilder) : LibC::Int

  fun tree_walk = git_tree_walk(tree : Tree, mode : TreewalkMode, callback : TreewalkCb, payload : Void*) : LibC::Int
  fun tree_dup = git_tree_dup(out_tree : Tree*, source : Tree) : LibC::Int
  fun tree_create_updated = git_tree_create_updated(out_oid : Oid*, repo : Repository, baseline : Tree, nupdates : LibC::SizeT, updates : TreeUpdate*) : LibC::Int
end
