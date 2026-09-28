# spec/amend_spec.cr
require "./spec_helper"

describe "amend" do
  after_each { Fixture.cleanup }

  it "replaces the HEAD message" do
    Fixture.with_repo("amend_message") do |repo, location|
      original = Fixture.seed(repo, location, "old message")

      stream = Git::Stream.new(repo)
      slot   = stream.amend("new message")
      stream.run.error.should be_nil
      stream.seal

      amended = stream[slot].as(Git::Oid)
      amended.should_not eq(original)
      Fixture.head(repo).should eq(amended)

      inspect = Git::Stream.new(repo)
      data    = inspect.read_object(amended.hex)
      inspect.run.error.should be_nil
      inspect.seal

      inspect[data].as(Git::ObjectData).text.should contain("new message")
    end
  end

  it "keeps the message when none is given" do
    Fixture.with_repo("amend_keep") do |repo, location|
      Fixture.seed(repo, location, "kept message")

      stream = Git::Stream.new(repo)
      slot   = stream.amend
      stream.run.error.should be_nil
      stream.seal

      inspect = Git::Stream.new(repo)
      data    = inspect.read_object(stream[slot].as(Git::Oid).hex)
      inspect.run.error.should be_nil
      inspect.seal

      inspect[data].as(Git::ObjectData).text.should contain("kept message")
    end
  end

  it "folds staged changes into HEAD" do
    Fixture.with_repo("amend_staged") do |repo, location|
      Fixture.seed(repo, location)
      Fixture.write(location, "extra.txt", "extra\n")

      stream = Git::Stream.new(repo)
      stream.stage("extra.txt")
      slot = stream.amend("seed plus extra")
      stream.run.error.should be_nil
      stream.seal

      inspect = Git::Stream.new(repo)
      blob    = inspect.read_blob("#{stream[slot].as(Git::Oid).hex}:extra.txt")
      inspect.run.error.should be_nil
      inspect.seal

      String.new(inspect[blob].as(Bytes)).should eq("extra\n")
    end
  end

  it "is refused on an unborn HEAD" do
    Fixture.with_repo("amend_unborn") do |repo, _|
      stream = Git::Stream.new(repo)
      stream.amend("nothing")
      stream.run.error.should be_a(Git::Err)
    end
  end

  it "rolls back to the original HEAD" do
    Fixture.with_repo("amend_rollback") do |repo, location|
      original = Fixture.seed(repo, location, "original")

      stream = Git::Stream.new(repo)
      stream.amend("replaced")
      stream.run.error.should be_nil
      Fixture.head(repo).should_not eq(original)

      stream.rollback.should be_nil
      stream.seal
      Fixture.head(repo).should eq(original)
    end
  end
end
