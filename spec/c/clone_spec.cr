# spec/c/clone_spec.cr
require "../spec_helper"

describe "LibGit2 Clone" do
  it "can initialize clone options" do
    opts = uninitialized LibGit2::CloneOptions

    # GIT_CLONE_OPTIONS_VERSION is 1
    result = LibGit2.clone_options_init(pointerof(opts), 1_u32)
    result.should eq(0)

    opts.version.should eq(1_u32)
  end
end
