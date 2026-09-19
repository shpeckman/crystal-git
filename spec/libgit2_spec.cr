# spec/libgit2_spec.cr
require "spec"
require "file_utils"
require "../src/crystal-git"

# Initialize libgit2 global state before any specs run
Spec.before_suite do
  LibGit2.libgit2_init
end

# Clean up libgit2 global state after all specs finish
Spec.after_suite do
  LibGit2.libgit2_shutdown
end

describe "LibGit2 Commit" do
  repo_path = "./tmp_commit_spec_repo"

  before_each do
    FileUtils.rm_rf(repo_path)
  end

  after_each do
    FileUtils.rm_rf(repo_path)
  end

  it "returns an error when looking up a non-existent commit" do
    repo_ptr = uninitialized LibGit2::Repository
    LibGit2.repository_init(pointerof(repo_ptr), repo_path, 1_u32)

    oid = uninitialized LibGit2::Oid
    LibGit2.oid_fromstr(pointerof(oid), "4a202b346bb0fb0db7eff3cffeb3c70babbd2045")

    commit_ptr = uninitialized LibGit2::Commit
    result = LibGit2.commit_lookup(pointerof(commit_ptr), repo_ptr, pointerof(oid))

    result.should_not eq(0)

    LibGit2.repository_free(repo_ptr)
  end
end

describe "LibGit2 Oid" do
  it "converts a string to an oid and formats it back" do
    sha = "4a202b346bb0fb0db7eff3cffeb3c70babbd2045"
    oid = uninitialized LibGit2::Oid

    result = LibGit2.oid_fromstr(pointerof(oid), sha)
    result.should eq(0)

    buffer = Bytes.new(41)
    LibGit2.oid_tostr(buffer.to_unsafe, 41_u64, pointerof(oid))

    String.new(buffer.to_unsafe).should eq(sha)
  end

  it "identifies zero oids" do
    oid = uninitialized LibGit2::Oid
    LibGit2.oid_fromstr(pointerof(oid), "0000000000000000000000000000000000000000")

    LibGit2.oid_is_zero(pointerof(oid)).should eq(1)
  end
end

describe "LibGit2 Repository" do
  repo_path = "./tmp_spec_repo"

  before_each do
    FileUtils.rm_rf(repo_path)
  end

  after_each do
    FileUtils.rm_rf(repo_path)
  end

  it "initializes and frees a bare repository" do
    repo_ptr = uninitialized LibGit2::Repository

    result = LibGit2.repository_init(pointerof(repo_ptr), repo_path, 1_u32)
    result.should eq(0)
    repo_ptr.null?.should be_false

    is_bare = LibGit2.repository_is_bare(repo_ptr)
    is_bare.should eq(1)

    LibGit2.repository_free(repo_ptr)
  end

  it "returns an error when opening a non-existent repository" do
    repo_ptr = uninitialized LibGit2::Repository
    result = LibGit2.repository_open(pointerof(repo_ptr), "./does_not_exist")

    result.should_not eq(0)
  end
end

describe "LibGit2 Signature" do
  it "creates and frees a signature" do
    sig_ptr = uninitialized Pointer(LibGit2::Signature)
    name  = "Test User"
    email = "test@example.com"

    result = LibGit2.signature_now(pointerof(sig_ptr), name, email)
    result.should eq(0)
    sig_ptr.null?.should be_false

    String.new(sig_ptr.value.name).should eq(name)
    String.new(sig_ptr.value.email).should eq(email)

    LibGit2.signature_free(sig_ptr)
  end
end

describe "LibGit2 Strarray" do
  it "can safely dispose an empty strarray" do
    arr = LibGit2::Strarray.new
    arr.strings = Pointer(Pointer(LibC::Char)).null
    arr.count = 0_u64

    LibGit2.strarray_dispose(pointerof(arr))

    arr.strings.null?.should be_true
    arr.count.should eq(0_u64)
  end
end

describe "LibGit2 Tree" do
  repo_path = "./tmp_tree_spec_repo"

  before_each do
    FileUtils.rm_rf(repo_path)
  end

  after_each do
    FileUtils.rm_rf(repo_path)
  end

  it "can create an empty treebuilder, check entrycount, and write it to the db" do
    repo_ptr = uninitialized LibGit2::Repository
    LibGit2.repository_init(pointerof(repo_ptr), repo_path, 1_u32)

    builder_ptr = uninitialized LibGit2::Treebuilder
    result = LibGit2.treebuilder_new(pointerof(builder_ptr), repo_ptr, Pointer(Void).null.as(LibGit2::Tree))
    result.should eq(0)

    count = LibGit2.treebuilder_entrycount(builder_ptr)
    count.should eq(0_u64)

    oid = uninitialized LibGit2::Oid
    write_result = LibGit2.treebuilder_write(pointerof(oid), builder_ptr)
    write_result.should eq(0)

    LibGit2.treebuilder_free(builder_ptr)
    LibGit2.repository_free(repo_ptr)
  end
end

describe "LibGit2 Buffer" do
  it "can safely dispose an empty buffer" do
    buf = LibGit2::Buf.new
    buf.ptr = Pointer(LibC::Char).null
    buf.reserved = 0_u64
    buf.size = 0_u64

    LibGit2.buf_dispose(pointerof(buf))

    buf.ptr.null?.should be_false
    String.new(buf.ptr).should eq("")
    buf.size.should eq(0_u64)
  end
end

describe "LibGit2 Errors" do
  it "can set and retrieve the last error" do
    LibGit2.err_clear

    message = "Test error message"
    result  = LibGit2.err_set_str(LibGit2::ErrorType::INVALID.value, message)
    result.should eq(0)

    err = LibGit2.err_last
    err.null?.should be_false

    String.new(err.value.message).should eq(message)
    err.value.klass.should eq(LibGit2::ErrorType::INVALID.value)
  end

  it "returns null when cleared" do
    LibGit2.err_set_str(LibGit2::ErrorType::INVALID.value, "Temp error")
    LibGit2.err_clear

    err = LibGit2.err_last
    (err.null? || err.value.klass == LibGit2::ErrorType::NONE.value).should be_true
  end
end

describe "LibGit2 Blob" do
  repo_path = "./tmp_blob_spec_repo"

  before_each do
    FileUtils.rm_rf(repo_path)
  end

  after_each do
    FileUtils.rm_rf(repo_path)
  end

  it "creates a blob from a buffer and reads it back" do
    repo_ptr = uninitialized LibGit2::Repository
    LibGit2.repository_init(pointerof(repo_ptr), repo_path, 1_u32)

    content = "Hello, Crystal Git!"
    oid = uninitialized LibGit2::Oid

    result = LibGit2.blob_create_from_buffer(
      pointerof(oid),
      repo_ptr,
      content.to_unsafe.as(Pointer(Void)),
      content.bytesize.to_u64
    )
    result.should eq(0)

    blob_ptr = uninitialized LibGit2::Blob
    lookup_result = LibGit2.blob_lookup(pointerof(blob_ptr), repo_ptr, pointerof(oid))
    lookup_result.should eq(0)

    LibGit2.blob_rawsize(blob_ptr).should eq(content.bytesize.to_u64)

    raw_content = LibGit2.blob_rawcontent(blob_ptr)
    String.new(raw_content.as(Pointer(UInt8)), content.bytesize).should eq(content)

    LibGit2.blob_free(blob_ptr)
    LibGit2.repository_free(repo_ptr)
  end
end

describe "LibGit2 Checkout" do
  it "can initialize checkout options" do
    opts = uninitialized LibGit2::CheckoutOptions

    # GIT_CHECKOUT_OPTIONS_VERSION is 1
    result = LibGit2.checkout_options_init(pointerof(opts), 1_u32)
    result.should eq(0)

    opts.version.should eq(1_u32)
  end
end

describe "LibGit2 Clone" do
  it "can initialize clone options" do
    opts = uninitialized LibGit2::CloneOptions

    # GIT_CLONE_OPTIONS_VERSION is 1
    result = LibGit2.clone_options_init(pointerof(opts), 1_u32)
    result.should eq(0)

    opts.version.should eq(1_u32)
  end
end

describe "LibGit2 Config" do
  cfg_path = "./tmp_config_spec_file"

  before_each do
    FileUtils.rm_rf(cfg_path)
    File.write(cfg_path, "")
  end

  after_each do
    FileUtils.rm_rf(cfg_path)
  end

  it "creates a new config on disk and sets values" do
    cfg_ptr = uninitialized LibGit2::Config
    LibGit2.config_open_ondisk(pointerof(cfg_ptr), cfg_path).should eq(0)

    # Set and assert a string value
    LibGit2.config_set_string(cfg_ptr, "user.name", "Crystal Dev").should eq(0)

    buf = LibGit2::Buf.new
    LibGit2.config_get_string_buf(pointerof(buf), cfg_ptr, "user.name").should eq(0)
    String.new(buf.ptr).should eq("Crystal Dev")
    LibGit2.buf_dispose(pointerof(buf))

    # Set and assert an int32 value
    LibGit2.config_set_int32(cfg_ptr, "core.dummy", 42).should eq(0)

    val = uninitialized Int32
    LibGit2.config_get_int32(pointerof(val), cfg_ptr, "core.dummy").should eq(0)
    val.should eq(42)

    LibGit2.config_free(cfg_ptr)
  end
end

describe "LibGit2 Index" do
  it "creates an empty in-memory index" do
    idx_ptr = uninitialized LibGit2::Index
    result = LibGit2.index_new(pointerof(idx_ptr))

    result.should eq(0)
    idx_ptr.null?.should be_false

    LibGit2.index_entrycount(idx_ptr).should eq(0_u64)
    LibGit2.index_has_conflicts(idx_ptr).should eq(0)

    LibGit2.index_free(idx_ptr)
  end
end

describe "LibGit2 ODB" do
  repo_path = "./tmp_odb_spec_repo"

  before_each do
    FileUtils.rm_rf(repo_path)
  end

  after_each do
    FileUtils.rm_rf(repo_path)
  end

  it "gets a repo ODB and writes a loose object" do
    repo_ptr = uninitialized LibGit2::Repository
    LibGit2.repository_init(pointerof(repo_ptr), repo_path, 1_u32).should eq(0)

    odb_ptr = uninitialized LibGit2::Odb
    LibGit2.repository_odb(pointerof(odb_ptr), repo_ptr).should eq(0)

    content = "Test object data"
    oid = uninitialized LibGit2::Oid

    result = LibGit2.odb_write(
      pointerof(oid),
      odb_ptr,
      content.to_unsafe.as(Pointer(Void)),
      content.bytesize.to_u64,
      LibGit2::ObjectType::BLOB
    )
    result.should eq(0)

    exists = LibGit2.odb_exists(odb_ptr, pointerof(oid))
    exists.should eq(1)

    LibGit2.odb_free(odb_ptr)
    LibGit2.repository_free(repo_ptr)
  end
end

describe "LibGit2 Refs" do
  repo_path = "./tmp_refs_spec_repo"

  before_each do
    FileUtils.rm_rf(repo_path)
  end

  after_each do
    FileUtils.rm_rf(repo_path)
  end

  it "creates and resolves a symbolic reference" do
    repo_ptr = uninitialized LibGit2::Repository
    LibGit2.repository_init(pointerof(repo_ptr), repo_path, 1_u32)

    ref_ptr = uninitialized LibGit2::Reference
    result = LibGit2.reference_symbolic_create(
      pointerof(ref_ptr),
      repo_ptr,
      "HEAD",
      "refs/heads/master",
      1,
      "test log"
    )
    result.should eq(0)

    ref_type = LibGit2.reference_type(ref_ptr)
    ref_type.should eq(LibGit2::ReferenceType::SYMBOLIC)

    target = LibGit2.reference_symbolic_target(ref_ptr)
    String.new(target.as(Pointer(UInt8))).should eq("refs/heads/master")

    LibGit2.reference_free(ref_ptr)
    LibGit2.repository_free(repo_ptr)
  end
end

describe "LibGit2 Status" do
  it "can initialize status options" do
    opts = uninitialized LibGit2::StatusOptions

    # GIT_STATUS_OPTIONS_VERSION is 1
    result = LibGit2.status_options_init(pointerof(opts), 1_u32)
    result.should eq(0)

    opts.version.should eq(1_u32)
  end
end

describe "LibGit2 Blame" do
  it "can initialize blame options" do
    opts = uninitialized LibGit2::BlameOptions

    # GIT_BLAME_OPTIONS_VERSION is 1
    result = LibGit2.blame_options_init(pointerof(opts), 1_u32)
    result.should eq(0)

    opts.version.should eq(1_u32)
  end
end

describe "LibGit2 Branch" do
  it "can check if a branch name is valid" do
    valid = uninitialized LibC::Int

    result = LibGit2.branch_name_is_valid(pointerof(valid), "master")
    result.should eq(0)
    valid.should eq(1)

    result = LibGit2.branch_name_is_valid(pointerof(valid), "..invalid")
    result.should eq(0)
    valid.should eq(0)
  end
end

describe "LibGit2 Credential" do
  it "creates a userpass plaintext credential" do
    cred_ptr = uninitialized LibGit2::Credential

    result = LibGit2.credential_userpass_plaintext_new(pointerof(cred_ptr), "user", "pass")
    result.should eq(0)

    has_user = LibGit2.credential_has_username(cred_ptr)
    has_user.should eq(1)

    username = LibGit2.credential_get_username(cred_ptr)
    String.new(username).should eq("user")

    LibGit2.credential_free(cred_ptr)
  end
end

describe "LibGit2 Diff" do
  it "can initialize diff options" do
    opts = uninitialized LibGit2::DiffOptions

    # GIT_DIFF_OPTIONS_VERSION is 1
    result = LibGit2.diff_options_init(pointerof(opts), 1_u32)
    result.should eq(0)

    opts.version.should eq(1_u32)
  end
end

describe "LibGit2 Merge" do
  it "can initialize merge options" do
    opts = uninitialized LibGit2::MergeOptions

    # GIT_MERGE_OPTIONS_VERSION is 1
    result = LibGit2.merge_options_init(pointerof(opts), 1_u32)
    result.should eq(0)

    opts.version.should eq(1_u32)
  end
end

describe "LibGit2 Proxy" do
  it "can initialize proxy options" do
    opts = uninitialized LibGit2::ProxyOptions

    # GIT_PROXY_OPTIONS_VERSION is 1
    result = LibGit2.proxy_options_init(pointerof(opts), 1_u32)
    result.should eq(0)

    opts.version.should eq(1_u32)
  end
end

describe "LibGit2 Rebase" do
  it "can initialize rebase options" do
    opts = uninitialized LibGit2::RebaseOptions

    # GIT_REBASE_OPTIONS_VERSION is 1
    result = LibGit2.rebase_options_init(pointerof(opts), 1_u32)
    result.should eq(0)

    opts.version.should eq(1_u32)
  end
end

describe "LibGit2 Remote" do
  it "can initialize fetch options" do
    opts = uninitialized LibGit2::FetchOptions

    # GIT_FETCH_OPTIONS_VERSION is 1
    result = LibGit2.fetch_options_init(pointerof(opts), 1_u32)
    result.should eq(0)

    opts.version.should eq(1) # Bound to LibC::Int in the struct
  end

  it "can initialize push options" do
    opts = uninitialized LibGit2::PushOptions

    # GIT_PUSH_OPTIONS_VERSION is 1
    result = LibGit2.push_options_init(pointerof(opts), 1_u32)
    result.should eq(0)

    opts.version.should eq(1_u32)
  end
end

describe "LibGit2 Patch" do
  it "creates a patch from memory buffers" do
    old_content = "Hello World\n"
    new_content = "Hello Crystal\n"

    patch_ptr = uninitialized LibGit2::Patch
    diff_opts = uninitialized LibGit2::DiffOptions
    LibGit2.diff_options_init(pointerof(diff_opts), 1_u32)

    result = LibGit2.patch_from_buffers(
      pointerof(patch_ptr),
      old_content.to_unsafe.as(Pointer(Void)),
      old_content.bytesize.to_u64,
      "file.txt",
      new_content.to_unsafe.as(Pointer(Void)),
      new_content.bytesize.to_u64,
      "file.txt",
      pointerof(diff_opts)
    )

    result.should eq(0)
    patch_ptr.null?.should be_false

    hunks = LibGit2.patch_num_hunks(patch_ptr)
    hunks.should eq(1_u64)

    LibGit2.patch_free(patch_ptr)
  end
end

describe "LibGit2 Reflog" do
  repo_path = "./tmp_reflog_spec_repo"

  before_each do
    FileUtils.rm_rf(repo_path)
  end

  after_each do
    FileUtils.rm_rf(repo_path)
  end

  it "reads an empty reflog when the reference does not exist yet" do
    repo_ptr = uninitialized LibGit2::Repository
    LibGit2.repository_init(pointerof(repo_ptr), repo_path, 1_u32).should eq(0)

    reflog_ptr = uninitialized LibGit2::Reflog
    result = LibGit2.reflog_read(pointerof(reflog_ptr), repo_ptr, "refs/heads/does_not_exist")

    # LibGit2 successfully reads non-existent reflogs by returning an empty reflog object
    result.should eq(0)
    reflog_ptr.null?.should be_false

    count = LibGit2.reflog_entrycount(reflog_ptr)
    count.should eq(0_u64)

    LibGit2.reflog_free(reflog_ptr)
    LibGit2.repository_free(repo_ptr)
  end
end

describe "LibGit2 Reset" do
  repo_path = "./tmp_reset_spec_repo"

  before_each do
    FileUtils.rm_rf(repo_path)
  end

  after_each do
    FileUtils.rm_rf(repo_path)
  end

  it "fails to reset an empty repository" do
    repo_ptr = uninitialized LibGit2::Repository
    LibGit2.repository_init(pointerof(repo_ptr), repo_path, 1_u32).should eq(0)

    obj_ptr = Pointer(Void).null.as(LibGit2::Object)
    paths   = Pointer(LibGit2::Strarray).null

    result = LibGit2.reset_default(repo_ptr, obj_ptr, paths)

    # Expect error because an empty repository with an unborn branch cannot be reset
    result.should_not eq(0)

    LibGit2.repository_free(repo_ptr)
  end
end

describe "LibGit2 Revparse" do
  repo_path = "./tmp_revparse_spec_repo"

  before_each do
    FileUtils.rm_rf(repo_path)
  end

  after_each do
    FileUtils.rm_rf(repo_path)
  end

  it "fails to revparse a non-existent spec" do
    repo_ptr = uninitialized LibGit2::Repository
    LibGit2.repository_init(pointerof(repo_ptr), repo_path, 1_u32).should eq(0)

    obj_ptr = uninitialized LibGit2::Object
    result = LibGit2.revparse_single(pointerof(obj_ptr), repo_ptr, "HEAD")

    # Expect error for resolving a spec in an empty repository
    result.should_not eq(0)

    LibGit2.repository_free(repo_ptr)
  end
end

describe "LibGit2 Stash" do
  it "can initialize stash options" do
    save_opts = uninitialized LibGit2::StashSaveOptions
    LibGit2.stash_save_options_init(pointerof(save_opts), 1_u32).should eq(0)
    save_opts.version.should eq(1_u32)

    apply_opts = uninitialized LibGit2::StashApplyOptions
    LibGit2.stash_apply_options_init(pointerof(apply_opts), 1_u32).should eq(0)
    apply_opts.version.should eq(1_u32)
  end
end

describe "LibGit2 Submodule" do
  it "can initialize submodule update options" do
    opts = uninitialized LibGit2::SubmoduleUpdateOptions

    # GIT_SUBMODULE_UPDATE_OPTIONS_VERSION is 1
    result = LibGit2.submodule_update_options_init(pointerof(opts), 1_u32)
    result.should eq(0)

    opts.version.should eq(1_u32)
  end
end

describe "LibGit2 Worktree" do
  it "can initialize worktree options" do
    add_opts = uninitialized LibGit2::WorktreeAddOptions
    LibGit2.worktree_add_options_init(pointerof(add_opts), 1_u32).should eq(0)
    add_opts.version.should eq(1_u32)

    prune_opts = uninitialized LibGit2::WorktreePruneOptions
    LibGit2.worktree_prune_options_init(pointerof(prune_opts), 1_u32).should eq(0)
    prune_opts.version.should eq(1_u32)
  end
end
