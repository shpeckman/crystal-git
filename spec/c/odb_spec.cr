# spec/c/odb_spec.cr
require "../spec_helper"
require "file_utils"

describe "LibGit2 ODB" do
  repo_path = "./tmp_odb_spec_repo"

  before_each do
    FileUtils.rm_rf(repo_path)
  end

  after_each do
    FileUtils.rm_rf(repo_path)
  end

  it "gets a repo ODB and writes a loose object" do
    repo_ptr = uninitialized LibGit2::Repository
    LibGit2.repository_init(pointerof(repo_ptr), repo_path, 1_u32).should eq(0)

    odb_ptr = uninitialized LibGit2::Odb
    LibGit2.repository_odb(pointerof(odb_ptr), repo_ptr).should eq(0)

    content = "Test object data"
    oid = uninitialized LibGit2::Oid

    result = LibGit2.odb_write(
      pointerof(oid),
      odb_ptr,
      content.to_unsafe.as(Pointer(Void)),
      content.bytesize.to_u64,
      LibGit2::ObjectType::BLOB
    )
    result.should eq(0)

    exists = LibGit2.odb_exists(odb_ptr, pointerof(oid))
    exists.should eq(1)

    LibGit2.odb_free(odb_ptr)
    LibGit2.repository_free(repo_ptr)
  end
end
