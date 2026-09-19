# spec/c/reflog_spec.cr
require "../spec_helper"
require "file_utils"

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
