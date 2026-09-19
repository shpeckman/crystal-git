# spec/c/index_spec.cr
require "../spec_helper"

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
