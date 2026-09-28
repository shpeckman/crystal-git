# spec/worktree_spec.cr
require "./spec_helper"

describe "linked worktrees" do
  after_each { Fixture.cleanup }

  it "adds and lists a worktree" do
    Fixture.with_repo("wt_add") do |repo, location|
      Fixture.seed(repo, location)
      target = Fixture.path("wt_add_linked")
      FileUtils.rm_rf(target)

      stream = Git::Stream.new(repo)
      stream.worktree_add("linked", target)
      list = stream.worktree_list
      stream.run.error.should be_nil

      File.exists?(File.join(target, "seed.txt")).should be_true
      names = stream[list].as(Array(Git::LinkedWorktree)).map(&.name)
      names.should contain("linked")
      stream.seal
    ensure
      FileUtils.rm_rf(Fixture.path("wt_add_linked"))
    end
  end

  it "adds a worktree for a branch ref" do
    Fixture.with_repo("wt_add_ref") do |repo, location|
      base = Fixture.seed(repo, location)

      setup = Git::Stream.new(repo)
      setup.create_branch("topic", base.hex)
      setup.run.error.should be_nil
      setup.seal

      target = Fixture.path("wt_add_ref_linked")
      FileUtils.rm_rf(target)

      stream = Git::Stream.new(repo)
      stream.worktree_add("topic_wt", target, ref: "topic")
      stream.run.error.should be_nil
      stream.seal

      File.exists?(File.join(target, "seed.txt")).should be_true
    ensure
      FileUtils.rm_rf(Fixture.path("wt_add_ref_linked"))
    end
  end

  it "removes a clean worktree" do
    Fixture.with_repo("wt_remove") do |repo, location|
      Fixture.seed(repo, location)
      target = Fixture.path("wt_remove_linked")
      FileUtils.rm_rf(target)

      setup = Git::Stream.new(repo)
      setup.worktree_add("linked", target)
      setup.run.error.should be_nil
      setup.seal

      stream = Git::Stream.new(repo, allow_irreversible: true)
      stream.worktree_remove("linked")
      list = stream.worktree_list
      stream.run.error.should be_nil
      stream.seal

      stream[list].as(Array(Git::LinkedWorktree)).should be_empty
      File.exists?(target).should be_false
    end
  end

  it "refuses to remove a dirty worktree without force" do
    Fixture.with_repo("wt_remove_dirty") do |repo, location|
      Fixture.seed(repo, location)
      target = Fixture.path("wt_remove_dirty_linked")
      FileUtils.rm_rf(target)

      setup = Git::Stream.new(repo)
      setup.worktree_add("linked", target)
      setup.run.error.should be_nil
      setup.seal

      Fixture.write(target, "dirty.txt", "dirty\n")

      stream = Git::Stream.new(repo, allow_irreversible: true)
      stream.worktree_remove("linked")
      stream.run.error.should be_a(Git::Err)

      forced = Git::Stream.new(repo, allow_irreversible: true)
      forced.worktree_remove("linked", force: true)
      forced.run.error.should be_nil
      forced.seal

      File.exists?(target).should be_false
    end
  end

  it "requires allow_irreversible for removal" do
    Fixture.with_repo("wt_remove_guard") do |repo, location|
      Fixture.seed(repo, location)
      target = Fixture.path("wt_remove_guard_linked")
      FileUtils.rm_rf(target)

      setup = Git::Stream.new(repo)
      setup.worktree_add("linked", target)
      setup.run.error.should be_nil
      setup.seal

      stream = Git::Stream.new(repo)
      stream.worktree_remove("linked")
      stream.run.error.should be_a(Git::Err)
    ensure
      FileUtils.rm_rf(Fixture.path("wt_remove_guard_linked"))
    end
  end

  it "prunes stale worktree metadata" do
    Fixture.with_repo("wt_prune") do |repo, location|
      Fixture.seed(repo, location)
      target = Fixture.path("wt_prune_linked")
      FileUtils.rm_rf(target)

      setup = Git::Stream.new(repo)
      setup.worktree_add("linked", target)
      setup.run.error.should be_nil
      setup.seal

      FileUtils.rm_rf(target)

      stream = Git::Stream.new(repo, allow_irreversible: true)
      slot   = stream.worktree_prune
      list   = stream.worktree_list
      stream.run.error.should be_nil
      stream.seal

      stream[slot].should eq(1)
      stream[list].as(Array(Git::LinkedWorktree)).should be_empty
    end
  end

  it "rolls back an added worktree" do
    Fixture.with_repo("wt_rollback") do |repo, location|
      Fixture.seed(repo, location)
      target = Fixture.path("wt_rollback_linked")
      FileUtils.rm_rf(target)

      stream = Git::Stream.new(repo)
      stream.worktree_add("linked", target)
      stream.run.error.should be_nil
      File.exists?(target).should be_true

      stream.rollback.should be_nil
      stream.seal

      check = Git::Stream.new(repo)
      list  = check.worktree_list
      check.run.error.should be_nil
      check.seal

      check[list].as(Array(Git::LinkedWorktree)).should be_empty
    end
  end
end
