# spec/c/merge_spec.cr
require "../spec_helper"

describe "LibGit2 Merge" do
  it "can initialize merge options" do
    opts = uninitialized LibGit2::MergeOptions

    # GIT_MERGE_OPTIONS_VERSION is 1
    result = LibGit2.merge_options_init(pointerof(opts), 1_u32)
    result.should eq(0)

    opts.version.should eq(1_u32)
  end
end
