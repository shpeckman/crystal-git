# spec/c/config_spec.cr
require "../spec_helper"
require "file_utils"

describe "LibGit2 Config" do
  cfg_path = "./tmp_config_spec_file"

  before_each do
    FileUtils.rm_rf(cfg_path)
    File.write(cfg_path, "")
  end

  after_each do
    FileUtils.rm_rf(cfg_path)
  end

  it "creates a new config on disk and sets values" do
    cfg_ptr = uninitialized LibGit2::Config
    LibGit2.config_open_ondisk(pointerof(cfg_ptr), cfg_path).should eq(0)

    # Set and assert a string value
    LibGit2.config_set_string(cfg_ptr, "user.name", "Crystal Dev").should eq(0)

    buf = LibGit2::Buf.new
    LibGit2.config_get_string_buf(pointerof(buf), cfg_ptr, "user.name").should eq(0)
    String.new(buf.ptr).should eq("Crystal Dev")
    LibGit2.buf_dispose(pointerof(buf))

    # Set and assert an int32 value
    LibGit2.config_set_int32(cfg_ptr, "core.dummy", 42).should eq(0)

    val = uninitialized Int32
    LibGit2.config_get_int32(pointerof(val), cfg_ptr, "core.dummy").should eq(0)
    val.should eq(42)

    LibGit2.config_free(cfg_ptr)
  end
end
