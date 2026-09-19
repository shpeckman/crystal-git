# spec/c/revparse_spec.cr
require "../spec_helper"
require "file_utils"

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
