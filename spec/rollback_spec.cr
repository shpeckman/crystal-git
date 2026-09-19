# spec/rollback_spec.cr
require "./spec_helper"

describe "rollback" do
  after_each { Fixture.cleanup }

  it "restores HEAD after rolling back a commit" do
    Fixture.with_repo("rollback_commit") do |repo, location|
      base = Fixture.seed(repo, location)
      Fixture.write(location, "b.txt", "b\n")

      stream = Git::Stream.new(repo)
      stream.stage("b.txt")
      stream.commit("second")
      stream.run.error.should be_nil

      Fixture.head(repo).should_not eq(base)

      stream.rollback.should be_nil
      stream.phase.should eq(Git::Stream::Phase::RolledBack)
      Fixture.head(repo).should eq(base)
      stream.seal
    end
  end

  it "removes a branch created by a rolled back stream" do
    Fixture.with_repo("rollback_branch") do |repo, location|
      base = Fixture.seed(repo, location)

      stream = Git::Stream.new(repo)
      stream.create_branch("topic", base.hex)
      stream.run.error.should be_nil

      Fixture.branch_names(repo).should contain("topic")

      stream.rollback.should be_nil
      stream.seal

      Fixture.branch_names(repo).should_not contain("topic")
    end
  end

  it "restores a branch deleted by a rolled back stream" do
    Fixture.with_repo("rollback_delete") do |repo, location|
      base = Fixture.seed(repo, location)

      create = Git::Stream.new(repo)
      create.create_branch("topic", base.hex)
      create.run.error.should be_nil
      create.seal

      stream = Git::Stream.new(repo)
      stream.delete_branch("topic")
      stream.run.error.should be_nil
      stream.rollback.should be_nil
      stream.seal

      Fixture.branch_names(repo).should contain("topic")
    end
  end

  it "restores the index after rolling back a stage" do
    Fixture.with_repo("rollback_index") do |repo, location|
      Fixture.seed(repo, location)
      Fixture.write(location, "b.txt", "b\n")

      stream = Git::Stream.new(repo)
      stream.stage("b.txt")
      stream.run.error.should be_nil

      repo.conditions.as(Git::Ok(Git::Conditions)).value.predicates.dirty_index?.should be_true

      stream.rollback.should be_nil
      stream.seal

      repo.conditions.as(Git::Ok(Git::Conditions)).value.predicates.dirty_index?.should be_false
    end
  end

  it "selects snapshot mode for worktree commands" do
    Fixture.with_repo("rollback_mode") do |repo, location|
      base = Fixture.seed(repo, location)

      create = Git::Stream.new(repo)
      create.create_branch("topic", base.hex)
      create.run.error.should be_nil
      create.seal

      stream = Git::Stream.new(repo)
      stream.checkout("topic")

      plan = stream.validate.as(Git::Ok(Git::Stream::Plan)).value
      plan.mode.should eq(Git::Stream::RollbackMode::Snapshot)
    end
  end

  it "restores the worktree and HEAD after a snapshot rollback" do
    Fixture.with_repo("rollback_snapshot") do |repo, location|
      base = Fixture.seed(repo, location)
      Fixture.commit(repo, location, "main.txt", "main\n", "main work")
      head = Fixture.head(repo)

      Fixture.write(location, "dirty.txt", "dirty\n")

      create = Git::Stream.new(repo)
      create.create_branch("topic", base.hex)
      create.run.error.should be_nil
      create.seal

      stream = Git::Stream.new(repo)
      stream.checkout("topic", :force)
      stream.run.error.should be_nil

      Fixture.head(repo).should eq(base)

      stream.rollback.should be_nil
      stream.seal

      Fixture.head(repo).should eq(head)
      repo.head_symbolic_name.as(Git::Ok(String)).value.should eq("refs/heads/master")
      File.exists?(File.join(location, "main.txt")).should be_true
      File.read(File.join(location, "dirty.txt")).should eq("dirty\n")
    end
  end

  it "clears integration state when rolling back a revert" do
    Fixture.with_repo("rollback_revert") do |repo, location|
      Fixture.seed(repo, location)
      target = Fixture.commit(repo, location, "gone.txt", "gone\n", "add gone")

      stream = Git::Stream.new(repo)
      stream.revert(target.hex)
      stream.run.error.should be_nil

      Fixture.state(repo).should eq(Git::State::Revert)

      stream.rollback.should be_nil
      stream.seal

      Fixture.state(repo).should eq(Git::State::Clean)
      Fixture.head(repo).should eq(target)
      File.exists?(File.join(location, "gone.txt")).should be_true
    end
  end

  it "drops a stash created by a rolled back stream" do
    Fixture.with_repo("rollback_stash") do |repo, location|
      Fixture.seed(repo, location)
      Fixture.write(location, "seed.txt", "changed\n")

      stage = Git::Stream.new(repo)
      stage.stage("seed.txt")
      stage.run.error.should be_nil
      stage.seal

      stream = Git::Stream.new(repo, allow_irreversible: true)
      stream.stash
      stream.run.error.should be_nil
      stream.rollback.should be_nil
      stream.seal

      list = Git::Stream.new(repo)
      slot = list.stash_list
      list.run.error.should be_nil
      list.seal

      list[slot].as(Array(Git::StashEntry)).should be_empty
    end
  end

  it "refuses to roll back a stream that never ran" do
    Fixture.with_repo("rollback_building") do |repo, _|
      stream = Git::Stream.new(repo)
      stream.rollback.should be_a(Git::Err)
    end
  end

  it "refuses to roll back twice" do
    Fixture.with_repo("rollback_twice") do |repo, location|
      Fixture.seed(repo, location)
      Fixture.write(location, "b.txt", "b\n")

      stream = Git::Stream.new(repo)
      stream.stage("b.txt")
      stream.run.error.should be_nil

      stream.rollback.should be_nil
      stream.rollback.should be_a(Git::Err)
      stream.seal
    end
  end

  it "refuses to roll back after sealing" do
    Fixture.with_repo("rollback_sealed") do |repo, location|
      Fixture.seed(repo, location)
      Fixture.write(location, "b.txt", "b\n")

      stream = Git::Stream.new(repo)
      stream.stage("b.txt")
      stream.run.error.should be_nil
      stream.seal.should be_nil

      stream.sealed?.should be_true
      stream.rollback.should be_a(Git::Err)
    end
  end
end
