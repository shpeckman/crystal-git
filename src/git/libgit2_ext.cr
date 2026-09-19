# src/git/libgit2_ext.cr
lib LibGit2
  fun object_lookup = git_object_lookup(object : Object*, repo : Repository, id : Oid*, type : ObjectType) : LibC::Int
  fun object_id = git_object_id(obj : Object) : Oid*
  fun object_type = git_object_type(obj : Object) : ObjectType
  fun object_peel = git_object_peel(peeled : Object*, object : Object, target_type : ObjectType) : LibC::Int
  fun object_free = git_object_free(object : Object)

  fun tag_lookup = git_tag_lookup(out_tag : Tag*, repo : Repository, id : Oid*) : LibC::Int
  fun tag_free = git_tag_free(tag : Tag)
  fun tag_id = git_tag_id(tag : Tag) : Oid*
  fun tag_name = git_tag_name(tag : Tag) : LibC::Char*
  fun tag_message = git_tag_message(tag : Tag) : LibC::Char*
  fun tag_target_id = git_tag_target_id(tag : Tag) : Oid*
  fun tag_create = git_tag_create(oid : Oid*, repo : Repository, tag_name : LibC::Char*, target : Object, tagger : Signature*, message : LibC::Char*, force : LibC::Int) : LibC::Int
  fun tag_create_lightweight = git_tag_create_lightweight(oid : Oid*, repo : Repository, tag_name : LibC::Char*, target : Object, force : LibC::Int) : LibC::Int
  fun tag_delete = git_tag_delete(repo : Repository, tag_name : LibC::Char*) : LibC::Int
  fun tag_list = git_tag_list(array : Strarray*, repo : Repository) : LibC::Int
  fun tag_name_is_valid = git_tag_name_is_valid(valid : LibC::Int*, name : LibC::Char*) : LibC::Int

  fun merge = git_merge(repo : Repository, their_heads : AnnotatedCommit*, their_heads_len : LibC::SizeT, merge_opts : MergeOptions*, checkout_opts : CheckoutOptions*) : LibC::Int

  struct CherrypickOptions
    version       : LibC::UInt
    mainline      : LibC::UInt
    merge_opts    : MergeOptions
    checkout_opts : CheckoutOptions
  end

  fun cherrypick_options_init = git_cherrypick_options_init(opts : CherrypickOptions*, version : LibC::UInt) : LibC::Int
  fun cherrypick = git_cherrypick(repo : Repository, commit : Commit, opts : CherrypickOptions*) : LibC::Int
  fun cherrypick_commit = git_cherrypick_commit(out_idx : Index*, repo : Repository, cherrypick_commit : Commit, our_commit : Commit, mainline : LibC::UInt, merge_options : MergeOptions*) : LibC::Int

  struct RevertOptions
    version       : LibC::UInt
    mainline      : LibC::UInt
    merge_opts    : MergeOptions
    checkout_opts : CheckoutOptions
  end

  fun revert_options_init = git_revert_options_init(opts : RevertOptions*, version : LibC::UInt) : LibC::Int
  fun revert = git_revert(repo : Repository, commit : Commit, given_opts : RevertOptions*) : LibC::Int
  fun revert_commit = git_revert_commit(out_idx : Index*, repo : Repository, revert_commit : Commit, our_commit : Commit, mainline : LibC::UInt, merge_options : MergeOptions*) : LibC::Int

  fun remote_lookup = git_remote_lookup(out_remote : Remote*, repo : Repository, name : LibC::Char*) : LibC::Int
  fun remote_create = git_remote_create(out_remote : Remote*, repo : Repository, name : LibC::Char*, url : LibC::Char*) : LibC::Int
  fun remote_create_anonymous = git_remote_create_anonymous(out_remote : Remote*, repo : Repository, url : LibC::Char*) : LibC::Int
  fun remote_free = git_remote_free(remote : Remote)
  fun remote_name = git_remote_name(remote : Remote) : LibC::Char*
  fun remote_url = git_remote_url(remote : Remote) : LibC::Char*
  fun remote_list = git_remote_list(out_array : Strarray*, repo : Repository) : LibC::Int
  fun remote_fetch = git_remote_fetch(remote : Remote, refspecs : Strarray*, opts : FetchOptions*, reflog_message : LibC::Char*) : LibC::Int
  fun remote_push = git_remote_push(remote : Remote, refspecs : Strarray*, opts : PushOptions*) : LibC::Int
  fun remote_prune = git_remote_prune(remote : Remote, callbacks : RemoteCallbacks*) : LibC::Int

  fun transaction_new = git_transaction_new(out_tx : Transaction*, repo : Repository) : LibC::Int
  fun transaction_lock_ref = git_transaction_lock_ref(tx : Transaction, refname : LibC::Char*) : LibC::Int
  fun transaction_set_target = git_transaction_set_target(tx : Transaction, refname : LibC::Char*, target : Oid*, sig : Signature*, msg : LibC::Char*) : LibC::Int
  fun transaction_set_symbolic_target = git_transaction_set_symbolic_target(tx : Transaction, refname : LibC::Char*, target : LibC::Char*, sig : Signature*, msg : LibC::Char*) : LibC::Int
  fun transaction_remove = git_transaction_remove(tx : Transaction, refname : LibC::Char*) : LibC::Int
  fun transaction_commit = git_transaction_commit(tx : Transaction) : LibC::Int
  fun transaction_free = git_transaction_free(tx : Transaction)
end
