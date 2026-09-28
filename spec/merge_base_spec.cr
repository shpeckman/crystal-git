# spec/merge_base_spec.cr
require "./spec_helper"

describe "merge_base" do
  after_each { Fixture.cleanup }

  it "finds the common ancestor of diverged branches" do
    Fixture.with_repo("merge_base_diverged") do |repo, location|
      base = Fixture.seed(repo, location)

      branch = Git::Stream.new(repo)
      branch.create_branch("topic", base.hex)
      branch.run.error.should be_nil
      branch.seal

      Fixture.commit(repo, location, "main.txt", "main\n", "main work")

      switch = Git::Stream.new(repo)
      switch.checkout("topic")
      switch.run.error.should be_nil
      switch.seal

      Fixture.commit(repo, location, "topic.txt", "topic\n", "topic work")

      stream = Git::Stream.new(repo)
      slot   = stream.merge_base("master", "topic")
      stream.run.error.should be_nil
      stream.seal

      stream[slot].as(Git::Oid).should eq(base)
    end
  end

  it "returns the ancestor for a linear history" do
    Fixture.with_repo("merge_base_linear") do |repo, location|
      base = Fixture.seed(repo, location)
      tip  = Fixture.commit(repo, location, "b.txt", "b\n", "second")

      stream = Git::Stream.new(repo)
      slot   = stream.merge_base(base.hex, tip.hex)
      stream.run.error.should be_nil
      stream.seal

      stream[slot].as(Git::Oid).should eq(base)
    end
  end

  it "fails when no merge base exists" do
    Fixture.with_repo("merge_base_none") do |repo, location|
      Fixture.seed(repo, location)

      stream = Git::Stream.new(repo)
      stream.merge_base("HEAD", "refs/tags/missing")
      report = stream.run
      report.error.should be_a(Git::Err)
    end
  end
end
