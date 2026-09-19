# spec/c/rebase_spec.cr
require "../spec_helper"

describe "LibGit2 Rebase" do
  it "can initialize rebase options" do
    opts = uninitialized LibGit2::RebaseOptions

    # GIT_REBASE_OPTIONS_VERSION is 1
    result = LibGit2.rebase_options_init(pointerof(opts), 1_u32)
    result.should eq(0)

    opts.version.should eq(1_u32)
  end
end
