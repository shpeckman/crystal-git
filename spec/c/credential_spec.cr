# spec/c/credential_spec.cr
require "../spec_helper"

describe "LibGit2 Credential" do
  it "creates a userpass plaintext credential" do
    cred_ptr = uninitialized LibGit2::Credential

    result = LibGit2.credential_userpass_plaintext_new(pointerof(cred_ptr), "user", "pass")
    result.should eq(0)

    has_user = LibGit2.credential_has_username(cred_ptr)
    has_user.should eq(1)

    username = LibGit2.credential_get_username(cred_ptr)
    String.new(username).should eq("user")

    LibGit2.credential_free(cred_ptr)
  end
end
