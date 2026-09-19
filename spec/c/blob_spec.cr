# spec/c/blob_spec.cr
require "../spec_helper"
require "file_utils"

describe "LibGit2 Blob" do
  repo_path = "./tmp_blob_spec_repo"

  before_each do
    FileUtils.rm_rf(repo_path)
  end

  after_each do
    FileUtils.rm_rf(repo_path)
  end

  it "creates a blob from a buffer and reads it back" do
    repo_ptr = uninitialized LibGit2::Repository
    LibGit2.repository_init(pointerof(repo_ptr), repo_path, 1_u32)

    content = "Hello, Crystal Git!"
    oid = uninitialized LibGit2::Oid

    result = LibGit2.blob_create_from_buffer(
      pointerof(oid),
      repo_ptr,
      content.to_unsafe.as(Pointer(Void)),
      content.bytesize.to_u64
    )
    result.should eq(0)

    blob_ptr = uninitialized LibGit2::Blob
    lookup_result = LibGit2.blob_lookup(pointerof(blob_ptr), repo_ptr, pointerof(oid))
    lookup_result.should eq(0)

    LibGit2.blob_rawsize(blob_ptr).should eq(content.bytesize.to_u64)

    raw_content = LibGit2.blob_rawcontent(blob_ptr)
    String.new(raw_content.as(Pointer(UInt8)), content.bytesize).should eq(content)

    LibGit2.blob_free(blob_ptr)
    LibGit2.repository_free(repo_ptr)
  end
end
