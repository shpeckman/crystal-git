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

  it "reports diff statistics" do
    Fixture.with_repo("diff_stats") do |repo, location|
      Fixture.seed(repo, location)
      Fixture.write(location, "seed.txt", "seed\none\ntwo\n")

      stream = Git::Stream.new(repo)
      stats  = stream.diff_stats
      stream.run.error.should be_nil
      stream.seal

      result = stream[stats].as(Git::DiffStats)
      result.files_changed.should eq(1)
      result.insertions.should eq(2)
      result.deletions.should eq(0)
      result.total.should eq(2)
    end
  end

  it "detects renames between trees when asked" do
    Fixture.with_repo("diff_renames") do |repo, location|
      base = Fixture.seed(repo, location)

      FileUtils.mv(File.join(location, "seed.txt"), File.join(location, "renamed.txt"))
      stage = Git::Stream.new(repo)
      stage.stage("renamed.txt")
      stage.remove("seed.txt")
      slot = stage.commit("rename")
      stage.run.error.should be_nil
      stage.seal
      renamed = stage[slot].as(Git::Oid)

      plain      = Git::Stream.new(repo)
      plain_slot = plain.diff(base.hex, renamed.hex)
      plain.run.error.should be_nil
      plain.seal

      statuses = plain[plain_slot].as(Array(Git::DiffEntry)).map(&.status)
      statuses.should contain(Git::DiffStatus::Deleted)
      statuses.should contain(Git::DiffStatus::Added)

      stream   = Git::Stream.new(repo)
      detected = stream.diff(base.hex, renamed.hex, renames: true)
      stream.run.error.should be_nil
      stream.seal

      entries = stream[detected].as(Array(Git::DiffEntry))
      entries.size.should eq(1)
      entries[0].status.should eq(Git::DiffStatus::Renamed)
      entries[0].old_path.should eq("seed.txt")
      entries[0].new_path.should eq("renamed.txt")
      entries[0].similarity.should eq(100)
    end
  end

  it "exposes structured hunks and lines" do
    Fixture.with_repo("diff_files") do |repo, location|
      Fixture.seed(repo, location)
      Fixture.write(location, "seed.txt", "seed\nadded\n")

      stream = Git::Stream.new(repo)
      files  = stream.diff_files
      stream.run.error.should be_nil
      stream.seal

      patches = stream[files].as(Array(Git::FilePatch))
      patches.size.should eq(1)

      file = patches[0]
      file.status.should eq(Git::DiffStatus::Modified)
      file.path.should eq("seed.txt")
      file.binary?.should be_false

      file.hunks.size.should eq(1)
      hunk = file.hunks[0]
      hunk.new_lines.should eq(2)

      additions = hunk.lines.select(&.addition?)
      additions.size.should eq(1)
      additions[0].content.should eq("added\n")
      additions[0].new_lineno.should eq(2)

      context = hunk.lines.select(&.context?)
      context.size.should eq(1)
      context[0].content.should eq("seed\n")
      context[0].old_lineno.should eq(1)
      context[0].new_lineno.should eq(1)
    end
  end
end
