# spec/c/patch_spec.cr
require "../spec_helper"

describe "LibGit2 Patch" do
  it "creates a patch from memory buffers" do
    old_content = "Hello World\n"
    new_content = "Hello Crystal\n"

    patch_ptr = uninitialized LibGit2::Patch
    diff_opts = uninitialized LibGit2::DiffOptions
    LibGit2.diff_options_init(pointerof(diff_opts), 1_u32)

    result = LibGit2.patch_from_buffers(
      pointerof(patch_ptr),
      old_content.to_unsafe.as(Pointer(Void)),
      old_content.bytesize.to_u64,
      "file.txt",
      new_content.to_unsafe.as(Pointer(Void)),
      new_content.bytesize.to_u64,
      "file.txt",
      pointerof(diff_opts)
    )

    result.should eq(0)
    patch_ptr.null?.should be_false

    hunks = LibGit2.patch_num_hunks(patch_ptr)
    hunks.should eq(1_u64)

    LibGit2.patch_free(patch_ptr)
  end
end
