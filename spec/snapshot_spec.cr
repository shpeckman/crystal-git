# spec/snapshot_spec.cr
require "./spec_helper"

private def conflicted(repo : Git::Repo, location : String) : Nil
  Fixture.seed(repo, location)
  Fixture.commit(repo, location, "file.txt", "base\n", "base file")

  create = Git::Stream.new(repo)
  create.create_branch("topic", "HEAD")
  create.run.error.should be_nil
  create.seal

  Fixture.commit(repo, location, "file.txt", "ours\n", "our edit")

  checkout = Git::Stream.new(repo)
  checkout.checkout("topic")
  checkout.run.error.should be_nil
  checkout.seal

  Fixture.commit(repo, location, "file.txt", "theirs\n", "their edit")

  back = Git::Stream.new(repo)
  back.checkout(Fixture::BRANCH)
  back.run.error.should be_nil
  back.seal

  merge   = Git::Stream.new(repo)
  outcome = merge.merge("topic")
  merge.run.error.should be_nil
  merge.seal
  merge[outcome].should eq(Git::MergeOutcome::Conflicted)
end

describe Git::Snapshot do
  after_each { Fixture.cleanup }

  it "uses the stash backend on a clean repository" do
    Fixture.with_repo("snap_stashed") do |repo, location|
      Fixture.seed(repo, location)

      result = Git::Snapshot.capture(repo)
      result.should be_a(Git::Ok(Git::Snapshot))
      result.as(Git::Ok(Git::Snapshot)).value.should be_a(Git::Snapshot::Stashed)

      result.as(Git::Ok(Git::Snapshot)).value.discard(repo).should be_nil
    end
  end

  it "uses the manual backend when the index has conflicts" do
    Fixture.with_repo("snap_manual") do |repo, location|
      conflicted(repo, location)

      result = Git::Snapshot.capture(repo)
      result.should be_a(Git::Ok(Git::Snapshot))
      result.as(Git::Ok(Git::Snapshot)).value.should be_a(Git::Snapshot::Manual)
    end
  end

  it "uses the manual backend when an integration is in progress" do
    Fixture.with_repo("snap_state") do |repo, location|
      Fixture.seed(repo, location)
      target = Fixture.commit(repo, location, "gone.txt", "gone\n", "add gone")

      revert = Git::Stream.new(repo)
      revert.revert(target.hex)
      revert.run.error.should be_nil
      revert.seal

      result = Git::Snapshot.capture(repo)
      result.as(Git::Ok(Git::Snapshot)).value.should be_a(Git::Snapshot::Manual)
    end
  end

  it "restores conflict stages, worktree, and merge state" do
    Fixture.with_repo("snap_restore") do |repo, location|
      conflicted(repo, location)

      before = File.read(File.join(location, "file.txt"))
      head   = Fixture.head(repo)

      captured = Git::Snapshot.capture(repo).as(Git::Ok(Git::Snapshot)).value

      resolve = Git::Stream.new(repo)
      resolve.resolve_all(:ours)
      resolve.run.error.should be_nil
      resolve.seal

      repo.conditions.as(Git::Ok(Git::Conditions)).value.predicates.conflicted?.should be_false

      captured.restore(repo).should be_nil

      conditions = repo.conditions.as(Git::Ok(Git::Conditions)).value
      conditions.predicates.conflicted?.should be_true
      conditions.state.should eq(Git::State::Merge)
      Fixture.head(repo).should eq(head)
      File.read(File.join(location, "file.txt")).should eq(before)
    end
  end

  it "removes files created after the snapshot" do
    Fixture.with_repo("snap_extra") do |repo, location|
      conflicted(repo, location)

      captured = Git::Snapshot.capture(repo).as(Git::Ok(Git::Snapshot)).value

      Fixture.write(location, "appeared.txt", "new\n")
      File.exists?(File.join(location, "appeared.txt")).should be_true

      captured.restore(repo).should be_nil

      File.exists?(File.join(location, "appeared.txt")).should be_false
    end
  end

  it "discards without side effects on the manual backend" do
    Fixture.with_repo("snap_discard") do |repo, location|
      conflicted(repo, location)

      captured = Git::Snapshot.capture(repo).as(Git::Ok(Git::Snapshot)).value
      captured.discard(repo).should be_nil

      repo.conditions.as(Git::Ok(Git::Conditions)).value.predicates.conflicted?.should be_true
    end
  end
end
