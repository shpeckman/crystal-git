# spec/c/checkout_spec.cr
require "../spec_helper"

describe "LibGit2 Checkout" do
  it "can initialize checkout options" do
    opts = uninitialized LibGit2::CheckoutOptions

    # GIT_CHECKOUT_OPTIONS_VERSION is 1
    result = LibGit2.checkout_options_init(pointerof(opts), 1_u32)
    result.should eq(0)

    opts.version.should eq(1_u32)
  end
end
