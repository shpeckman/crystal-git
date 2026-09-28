# spec/diff_spec.cr
require "./spec_helper"

describe "diff" do
  after_each { Fixture.cleanup }

  it "lists unstaged modifications against the index" do
    Fixture.with_repo("diff_workdir") do |repo, location|
      Fixture.seed(repo, location)
      Fixture.write(location, "seed.txt", "changed\n")

      stream = Git::Stream.new(repo)
      slot   = stream.diff
      stream.run.error.should be_nil
      stream.seal

      entries = stream[slot].as(Array(Git::DiffEntry))
      entries.size.should eq(1)
      entries[0].status.should eq(Git::DiffStatus::Modified)
      entries[0].path.should eq("seed.txt")
    end
  end

  it "excludes untracked files by default" do
    Fixture.with_repo("diff_untracked") do |repo, location|
      Fixture.seed(repo, location)
      Fixture.write(location, "fresh.txt", "new\n")

      stream = Git::Stream.new(repo)
      slot   = stream.diff
      stream.run.error.should be_nil
      stream.seal

      stream[slot].as(Array(Git::DiffEntry)).should be_empty
    end
  end

  it "lists staged changes against HEAD" do
    Fixture.with_repo("diff_staged") do |repo, location|
      Fixture.seed(repo, location)
      Fixture.write(location, "added.txt", "added\n")

      stage = Git::Stream.new(repo)
      stage.stage("added.txt")
      stage.run.error.should be_nil
      stage.seal

      stream = Git::Stream.new(repo)
      slot   = stream.diff(staged: true)
      stream.run.error.should be_nil
      stream.seal

      entries = stream[slot].as(Array(Git::DiffEntry))
      entries.size.should eq(1)
      entries[0].status.should eq(Git::DiffStatus::Added)
      entries[0].path.should eq("added.txt")
    end
  end

  it "lists staged changes with an unborn HEAD" do
    Fixture.with_repo("diff_unborn") do |repo, location|
      Fixture.write(location, "first.txt", "first\n")

      stage = Git::Stream.new(repo)
      stage.stage("first.txt")
      stage.run.error.should be_nil
      stage.seal

      stream = Git::Stream.new(repo)
      slot   = stream.diff(staged: true)
      stream.run.error.should be_nil
      stream.seal

      entries = stream[slot].as(Array(Git::DiffEntry))
      entries.size.should eq(1)
      entries[0].status.should eq(Git::DiffStatus::Added)
    end
  end

  it "diffs a revision against the workdir" do
    Fixture.with_repo("diff_rev") do |repo, location|
      Fixture.seed(repo, location)
      Fixture.write(location, "seed.txt", "changed\n")

      stream = Git::Stream.new(repo)
      slot   = stream.diff("HEAD")
      stream.run.error.should be_nil
      stream.seal

      entries = stream[slot].as(Array(Git::DiffEntry))
      entries.size.should eq(1)
      entries[0].status.should eq(Git::DiffStatus::Modified)
    end
  end

  it "diffs two revisions" do
    Fixture.with_repo("diff_revs") do |repo, location|
      Fixture.seed(repo, location)
      Fixture.commit(repo, location, "second.txt", "second\n", "second commit")

      stream = Git::Stream.new(repo)
      slot   = stream.diff("HEAD~1", "HEAD")
      stream.run.error.should be_nil
      stream.seal

      entries = stream[slot].as(Array(Git::DiffEntry))
      entries.size.should eq(1)
      entries[0].status.should eq(Git::DiffStatus::Added)
      entries[0].path.should eq("second.txt")
    end
  end

  it "filters by path" do
    Fixture.with_repo("diff_paths") do |repo, location|
      Fixture.seed(repo, location)
      Fixture.write(location, "seed.txt", "changed\n")
      Fixture.write(location, "other.txt", "other\n")

      stage = Git::Stream.new(repo)
      stage.stage("other.txt")
      stage.run.error.should be_nil
      stage.seal

      stream = Git::Stream.new(repo)
      slot   = stream.diff(["seed.txt"])
      stream.run.error.should be_nil
      stream.seal

      entries = stream[slot].as(Array(Git::DiffEntry))
      entries.size.should eq(1)
      entries[0].path.should eq("seed.txt")
    end
  end

  it "renders a patch" do
    Fixture.with_repo("diff_patch") do |repo, location|
      Fixture.seed(repo, location)
      Fixture.write(location, "seed.txt", "changed\n")

      stream = Git::Stream.new(repo)
      slot   = stream.diff_patch
      stream.run.error.should be_nil
      stream.seal

      patch = stream[slot].as(String)
      patch.should contain("diff --git a/seed.txt b/seed.txt")
      patch.should contain("-seed")
      patch.should contain("+changed")
    end
  end
end
