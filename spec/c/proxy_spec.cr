# spec/c/proxy_spec.cr
require "../spec_helper"

describe "LibGit2 Proxy" do
  it "can initialize proxy options" do
    opts = uninitialized LibGit2::ProxyOptions

    # GIT_PROXY_OPTIONS_VERSION is 1
    result = LibGit2.proxy_options_init(pointerof(opts), 1_u32)
    result.should eq(0)

    opts.version.should eq(1_u32)
  end
end
