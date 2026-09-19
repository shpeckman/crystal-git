# spec/c/submodule_spec.cr
require "../spec_helper"

describe "LibGit2 Submodule" do
  it "can initialize submodule update options" do
    opts = uninitialized LibGit2::SubmoduleUpdateOptions

    # GIT_SUBMODULE_UPDATE_OPTIONS_VERSION is 1
    result = LibGit2.submodule_update_options_init(pointerof(opts), 1_u32)
    result.should eq(0)

    opts.version.should eq(1_u32)
  end
end
