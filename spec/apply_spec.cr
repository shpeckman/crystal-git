# spec/apply_spec.cr
require "./spec_helper"

describe "apply" do
  after_each { Fixture.cleanup }

  it "applies a patch to the workdir" do
    Fixture.with_repo("apply_workdir") do |repo, location|
      Fixture.seed(repo, location)

      Fixture.write(location, "seed.txt", "seed\nextra line\n")

      capture = Git::Stream.new(repo)
      patch   = capture.diff_patch("HEAD")
      capture.run.error.should be_nil
      capture.seal
      text = capture[patch].as(String)
      text.should contain("extra line")

      Fixture.write(location, "seed.txt", "seed\n")
      File.read(File.join(location, "seed.txt")).should eq("seed\n")

      stream  = Git::Stream.new(repo)
      applied = stream.apply(text)
      stream.run.error.should be_nil
      stream.seal

      stream[applied].should eq(1)
      File.read(File.join(location, "seed.txt")).should eq("seed\nextra line\n")
    end
  end

  it "applies a patch to the index only" do
    Fixture.with_repo("apply_index") do |repo, location|
      Fixture.seed(repo, location)

      Fixture.write(location, "seed.txt", "seed\nextra line\n")

      capture = Git::Stream.new(repo)
      patch   = capture.diff_patch("HEAD")
      capture.run.error.should be_nil
      capture.seal
      text = capture[patch].as(String)

      Fixture.write(location, "seed.txt", "seed\n")

      stream = Git::Stream.new(repo)
      stream.apply(text, Git::ApplyLocation::Index)
      staged = stream.diff(staged: true)
      stream.run.error.should be_nil
      stream.seal

      File.read(File.join(location, "seed.txt")).should eq("seed\n")

      entries = stream[staged].as(Array(Git::DiffEntry))
      entries.map(&.path).should contain("seed.txt")
    end
  end

  it "rolls back an applied patch" do
    Fixture.with_repo("apply_rollback") do |repo, location|
      Fixture.seed(repo, location)

      Fixture.write(location, "seed.txt", "seed\nextra line\n")

      capture = Git::Stream.new(repo)
      patch   = capture.diff_patch("HEAD")
      capture.run.error.should be_nil
      capture.seal
      text = capture[patch].as(String)

      Fixture.write(location, "seed.txt", "seed\n")

      stream = Git::Stream.new(repo)
      stream.apply(text)
      stream.run.error.should be_nil
      File.read(File.join(location, "seed.txt")).should eq("seed\nextra line\n")

      stream.rollback.should be_nil
      stream.seal

      File.read(File.join(location, "seed.txt")).should eq("seed\n")
    end
  end

  it "rejects a patch that does not apply" do
    Fixture.with_repo("apply_conflict") do |repo, location|
      Fixture.seed(repo, location)

      Fixture.write(location, "seed.txt", "seed\nextra line\n")

      capture = Git::Stream.new(repo)
      patch   = capture.diff_patch("HEAD")
      capture.run.error.should be_nil
      capture.seal
      text = capture[patch].as(String)

      Fixture.write(location, "seed.txt", "completely different\n")

      stream = Git::Stream.new(repo)
      stream.apply(text)
      stream.run.error.should be_a(Git::Err)
    end
  end
end
