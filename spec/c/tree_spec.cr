# spec/c/tree_spec.cr
require "../spec_helper"
require "file_utils"

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
