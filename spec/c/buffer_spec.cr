# spec/c/buffer_spec.cr
require "../spec_helper"

describe "LibGit2 Buffer" do
  it "can safely dispose an empty buffer" do
    buf = LibGit2::Buf.new
    buf.ptr = Pointer(LibC::Char).null
    buf.reserved = 0_u64
    buf.size = 0_u64

    LibGit2.buf_dispose(pointerof(buf))

    buf.ptr.null?.should be_true
    buf.size.should eq(0_u64)
  end
end
