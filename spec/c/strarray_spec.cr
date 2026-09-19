# spec/c/strarray_spec.cr
require "../spec_helper"

describe "LibGit2 Strarray" do
  it "can safely dispose an empty strarray" do
    arr = LibGit2::Strarray.new
    arr.strings = Pointer(Pointer(LibC::Char)).null
    arr.count = 0_u64

    LibGit2.strarray_dispose(pointerof(arr))

    arr.strings.null?.should be_true
    arr.count.should eq(0_u64)
  end
end
