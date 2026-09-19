# spec/c/errors_spec.cr
require "../spec_helper"

describe "LibGit2 Errors" do
  it "can set and retrieve the last error" do
    LibGit2.err_clear

    message = "Test error message"
    result  = LibGit2.err_set_str(LibGit2::ErrorType::INVALID.value, message)
    result.should eq(0)

    err = LibGit2.err_last
    err.null?.should be_false

    String.new(err.value.message).should eq(message)
    err.value.klass.should eq(LibGit2::ErrorType::INVALID.value)
  end

  it "returns null when cleared" do
    LibGit2.err_set_str(LibGit2::ErrorType::INVALID.value, "Temp error")
    LibGit2.err_clear

    err = LibGit2.err_last
    (err.null? || err.value.klass == LibGit2::ErrorType::NONE.value).should be_true
  end
end
