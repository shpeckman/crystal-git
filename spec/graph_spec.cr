# spec/graph_spec.cr
require "./spec_helper"

describe "graph commands" do
  after_each { Fixture.cleanup }

  it "calculates ahead and behind distances" do
    Fixture.with_repo("graph_ahead_behind") do |repo, location|
      base = Fixture.seed(repo, location)

      branch = Git::Stream.new(repo)
      branch.create_branch("topic", base.hex)
      branch.run.error.should be_nil
      branch.seal

      Fixture.commit(repo, location, "main.txt", "main\n", "main commit")

      checkout = Git::Stream.new(repo)
      checkout.checkout("topic")
      checkout.run.error.should be_nil
      checkout.seal

      Fixture.commit(repo, location, "topic1.txt", "1\n", "topic commit 1")
      Fixture.commit(repo, location, "topic2.txt", "2\n", "topic commit 2")

      stream = Git::Stream.new(repo)
      slot   = stream.ahead_behind("topic", Fixture::BRANCH)
      stream.run.error.should be_nil
      stream.seal

      res = stream[slot].as(Git::AheadBehind)
      res.ahead.should eq(2_u64)
      res.behind.should eq(1_u64)
    end
  end

  it "determines commit ancestry" do
    Fixture.with_repo("graph_descendant") do |repo, location|
      first  = Fixture.seed(repo, location)
      second = Fixture.commit(repo, location, "second.txt", "second\n", "second")

      stream         = Git::Stream.new(repo)
      is_descendant  = stream.descendant_of(second.hex, first.hex)
      not_descendant = stream.descendant_of(first.hex, second.hex)
      stream.run.error.should be_nil
      stream.seal

      stream[is_descendant].should eq(true)
      stream[not_descendant].should eq(false)
    end
  end

  it "checks if a commit is reachable from an array of descendants" do
    Fixture.with_repo("graph_reachable") do |repo, location|
      first = Fixture.seed(repo, location)

      branch = Git::Stream.new(repo)
      branch.create_branch("topic", first.hex)
      branch.run.error.should be_nil
      branch.seal

      Fixture.commit(repo, location, "main.txt", "main\n", "main commit")

      checkout = Git::Stream.new(repo)
      checkout.checkout("topic")
      checkout.run.error.should be_nil
      checkout.seal

      topic_commit = Fixture.commit(repo, location, "topic.txt", "topic\n", "topic commit")

      stream      = Git::Stream.new(repo)
      reachable   = stream.reachable_from_any(first.hex, [topic_commit.hex])
      unreachable = stream.reachable_from_any(topic_commit.hex, [first.hex])
      stream.run.error.should be_nil
      stream.seal

      stream[reachable].should eq(true)
      stream[unreachable].should eq(false)
    end
  end

  it "walks commits and applies limits" do
    Fixture.with_repo("graph_revwalk") do |repo, location|
      c1 = Fixture.seed(repo, location)
      c2 = Fixture.commit(repo, location, "2.txt", "2\n", "two")
      c3 = Fixture.commit(repo, location, "3.txt", "3\n", "three")

      stream     = Git::Stream.new(repo)
      all_slot   = stream.revwalk("HEAD")
      limit_slot = stream.revwalk("HEAD", limit: 2)
      stream.run.error.should be_nil
      stream.seal

      all_commits = stream[all_slot].as(Array(Git::Oid))
      all_commits.size.should eq(3)
      all_commits[0].should eq(c3)
      all_commits[1].should eq(c2)
      all_commits[2].should eq(c1)

      limited = stream[limit_slot].as(Array(Git::Oid))
      limited.size.should eq(2)
      limited[0].should eq(c3)
      limited[1].should eq(c2)
    end
  end

  it "writes a commit graph file" do
    Fixture.with_repo("graph_write_file") do |repo, location|
      Fixture.seed(repo, location)
      Fixture.commit(repo, location, "a.txt", "a\n", "add a")

      stream = Git::Stream.new(repo)
      slot   = stream.write_commit_graph
      stream.run.error.should be_nil
      stream.seal

      stream[slot].should eq(true)
      File.exists?(File.join(location, ".git", "objects", "info", "commit-graph")).should be_true
    end
  end
end
