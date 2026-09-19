# spec/c/stash_spec.cr
require "../spec_helper"

describe "LibGit2 Stash" do
  it "can initialize stash options" do
    save_opts = uninitialized LibGit2::StashSaveOptions
    LibGit2.stash_save_options_init(pointerof(save_opts), 1_u32).should eq(0)
    save_opts.version.should eq(1_u32)

    apply_opts = uninitialized LibGit2::StashApplyOptions
    LibGit2.stash_apply_options_init(pointerof(apply_opts), 1_u32).should eq(0)
    apply_opts.version.should eq(1_u32)
  end
end
