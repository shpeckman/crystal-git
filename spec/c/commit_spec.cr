# spec/c/commit_spec.cr
require "../spec_helper"
require "file_utils"

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
