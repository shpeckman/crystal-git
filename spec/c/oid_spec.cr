# spec/c/oid_spec.cr
require "../spec_helper"

describe "LibGit2 Oid" do
  it "converts a string to an oid and formats it back" do
    sha = "4a202b346bb0fb0db7eff3cffeb3c70babbd2045"
    oid = uninitialized LibGit2::Oid

    result = LibGit2.oid_fromstr(pointerof(oid), sha)
    result.should eq(0)

    buffer = Bytes.new(41)
    LibGit2.oid_tostr(buffer.to_unsafe, 41_u64, pointerof(oid))

    String.new(buffer.to_unsafe).should eq(sha)
  end

  it "identifies zero oids" do
    oid = uninitialized LibGit2::Oid
    LibGit2.oid_fromstr(pointerof(oid), "0000000000000000000000000000000000000000")

    LibGit2.oid_is_zero(pointerof(oid)).should eq(1)
  end
end
