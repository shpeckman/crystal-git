# spec/c/refs_spec.cr
require "../spec_helper"
require "file_utils"

describe "LibGit2 Refs" do
  repo_path = "./tmp_refs_spec_repo"

  before_each do
    FileUtils.rm_rf(repo_path)
  end

  after_each do
    FileUtils.rm_rf(repo_path)
  end

  it "creates and resolves a symbolic reference" do
    repo_ptr = uninitialized LibGit2::Repository
    LibGit2.repository_init(pointerof(repo_ptr), repo_path, 1_u32)

    ref_ptr = uninitialized LibGit2::Reference
    result = LibGit2.reference_symbolic_create(
      pointerof(ref_ptr),
      repo_ptr,
      "HEAD",
      "refs/heads/master",
      1,
      "test log"
    )
    result.should eq(0)

    ref_type = LibGit2.reference_type(ref_ptr)
    ref_type.should eq(LibGit2::ReferenceType::SYMBOLIC)

    target = LibGit2.reference_symbolic_target(ref_ptr)
    String.new(target.as(Pointer(UInt8))).should eq("refs/heads/master")

    LibGit2.reference_free(ref_ptr)
    LibGit2.repository_free(repo_ptr)
  end
end
