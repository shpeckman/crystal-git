# spec/c/diff_spec.cr
require "../spec_helper"

describe "LibGit2 Diff" do
  it "can initialize diff options" do
    opts = uninitialized LibGit2::DiffOptions

    # GIT_DIFF_OPTIONS_VERSION is 1
    result = LibGit2.diff_options_init(pointerof(opts), 1_u32)
    result.should eq(0)

    opts.version.should eq(1_u32)
  end
end
