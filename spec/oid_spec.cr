# spec/oid_spec.cr
require "./spec_helper"

describe Git::Oid do
  sha = "4a202b346bb0fb0db7eff3cffeb3c70babbd2045"

  it "parses and formats a sha" do
    result = Git::Oid.parse(sha)
    result.should be_a(Git::Ok(Git::Oid))

    oid = result.as(Git::Ok(Git::Oid)).value
    oid.hex.should eq(sha)
    oid.to_s.should eq(sha)
  end

  it "reports a parse failure as an error" do
    result = Git::Oid.parse("not a sha")
    result.should be_a(Git::Err)
  end

  it "identifies the zero oid" do
    result = Git::Oid.parse("0" * 40)
    oid    = result.as(Git::Ok(Git::Oid)).value

    oid.zero?.should be_true
  end

  it "compares by value" do
    left  = Git::Oid.parse(sha).as(Git::Ok(Git::Oid)).value
    right = Git::Oid.parse(sha).as(Git::Ok(Git::Oid)).value
    other = Git::Oid.parse("0" * 40).as(Git::Ok(Git::Oid)).value

    (left == right).should be_true
    (left == other).should be_false
  end
end
