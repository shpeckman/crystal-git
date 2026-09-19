# spec/c/status_spec.cr
require "../spec_helper"

describe "LibGit2 Status" do
  it "can initialize status options" do
    opts = uninitialized LibGit2::StatusOptions

    # GIT_STATUS_OPTIONS_VERSION is 1
    result = LibGit2.status_options_init(pointerof(opts), 1_u32)
    result.should eq(0)

    opts.version.should eq(1_u32)
  end
end
