# spec/c/repository_spec.cr
require "../spec_helper"
require "file_utils"

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
