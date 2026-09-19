# spec/c/remote_spec.cr
require "../spec_helper"

describe "LibGit2 Remote" do
  it "can initialize fetch options" do
    opts = uninitialized LibGit2::FetchOptions

    # GIT_FETCH_OPTIONS_VERSION is 1
    result = LibGit2.fetch_options_init(pointerof(opts), 1_u32)
    result.should eq(0)

    opts.version.should eq(1) # Bound to LibC::Int in the struct
  end

  it "can initialize push options" do
    opts = uninitialized LibGit2::PushOptions

    # GIT_PUSH_OPTIONS_VERSION is 1
    result = LibGit2.push_options_init(pointerof(opts), 1_u32)
    result.should eq(0)

    opts.version.should eq(1_u32)
  end
end
