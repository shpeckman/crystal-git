# spec/c/signature_spec.cr
require "../spec_helper"

describe "LibGit2 Signature" do
  it "creates and frees a signature" do
    sig_ptr = uninitialized Pointer(LibGit2::Signature)
    name  = "Test User"
    email = "test@example.com"

    result = LibGit2.signature_now(pointerof(sig_ptr), name, email)
    result.should eq(0)
    sig_ptr.null?.should be_false

    String.new(sig_ptr.value.name).should eq(name)
    String.new(sig_ptr.value.email).should eq(email)

    LibGit2.signature_free(sig_ptr)
  end
end
