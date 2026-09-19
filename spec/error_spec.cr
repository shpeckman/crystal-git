# spec/error_spec.cr
require "./spec_helper"

describe Git::Err do
  it "captures the thread-local libgit2 error" do
    LibGit2.err_clear
    LibGit2.err_set_str(LibGit2::ErrorType::REFERENCE.value, "spec failure")

    err = Git::Err.capture(LibGit2::ErrorCode::ENOTFOUND.value)

    err.code.should eq(LibGit2::ErrorCode::ENOTFOUND)
    err.klass.should eq(LibGit2::ErrorType::REFERENCE)
    err.message.should eq("spec failure")
  end

  it "builds invalid errors without touching libgit2 state" do
    err = Git::Err.invalid("bad input")

    err.code.should eq(LibGit2::ErrorCode::EINVALID)
    err.message.should eq("bad input")
    err.err?.should be_true
    err.ok?.should be_false
  end
end

describe Git do
  it "returns nil for successful return codes" do
    Git.check(0).should be_nil
    Git.check(1).should be_nil
  end

  it "returns an error for negative return codes" do
    LibGit2.err_clear
    LibGit2.err_set_str(LibGit2::ErrorType::ODB.value, "odb failure")

    err = Git.check(LibGit2::ErrorCode::ERROR.value)
    err.should_not be_nil
    err.as(Git::Err).message.should eq("odb failure")
  end
end

describe Git::Ok do
  it "wraps a value" do
    result = Git::Ok(Int32).new(42)

    result.value.should eq(42)
    result.ok?.should be_true
    result.err?.should be_false
  end
end
