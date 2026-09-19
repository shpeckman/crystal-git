# spec/c/worktree_spec.cr
require "../spec_helper"

describe "LibGit2 Worktree" do
  it "can initialize worktree options" do
    add_opts = uninitialized LibGit2::WorktreeAddOptions
    LibGit2.worktree_add_options_init(pointerof(add_opts), 1_u32).should eq(0)
    add_opts.version.should eq(1_u32)

    prune_opts = uninitialized LibGit2::WorktreePruneOptions
    LibGit2.worktree_prune_options_init(pointerof(prune_opts), 1_u32).should eq(0)
    prune_opts.version.should eq(1_u32)
  end
end
