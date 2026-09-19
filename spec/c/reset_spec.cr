# spec/c/reset_spec.cr
require "../spec_helper"
require "file_utils"

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
