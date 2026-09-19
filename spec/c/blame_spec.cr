# spec/c/blame_spec.cr
require "../spec_helper"

describe "LibGit2 Blame" do
  it "can initialize blame options" do
    opts = uninitialized LibGit2::BlameOptions

    # GIT_BLAME_OPTIONS_VERSION is 1
    result = LibGit2.blame_options_init(pointerof(opts), 1_u32)
    result.should eq(0)

    opts.version.should eq(1_u32)
  end
end
