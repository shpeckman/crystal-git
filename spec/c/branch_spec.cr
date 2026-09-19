# spec/c/branch_spec.cr
require "../spec_helper"

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
