# spec/reflog_spec.cr
require "./spec_helper"

describe "reflog" do
  after_each { Fixture.cleanup }

  it "reads the HEAD reflog newest first" do
    Fixture.with_repo("reflog_head") do |repo, location|
      first  = Fixture.seed(repo, location, "first")
      second = Fixture.commit(repo, location, "b.txt", "b\n", "second")

      stream = Git::Stream.new(repo)
      slot   = stream.reflog
      stream.run.error.should be_nil
      stream.seal

      entries = stream[slot].as(Array(Git::ReflogEntry))
      entries.size.should eq(2)

      entries[0].new_oid.should eq(second)
      entries[0].old_oid.should eq(first)
      entries[0].message.should contain("second")
      entries[0].committer.should eq("Spec Runner")

      entries[1].new_oid.should eq(first)
      entries[1].old_oid.zero?.should be_true
    end
  end

  it "reads a branch reflog" do
    Fixture.with_repo("reflog_branch") do |repo, location|
      Fixture.seed(repo, location)

      stream = Git::Stream.new(repo)
      slot   = stream.reflog("refs/heads/master")
      stream.run.error.should be_nil
      stream.seal

      entries = stream[slot].as(Array(Git::ReflogEntry))
      entries.size.should eq(1)
    end
  end

  it "fails for a ref without a reflog" do
    Fixture.with_repo("reflog_missing") do |repo, location|
      Fixture.seed(repo, location)

      stream = Git::Stream.new(repo)
      stream.reflog("refs/heads/nonexistent")
      stream.run.error.should be_a(Git::Err)
    end
  end
end
