# spec/blame_spec.cr
require "./spec_helper"

describe "blame" do
  after_each { Fixture.cleanup }

  it "blames a single-commit file" do
    Fixture.with_repo("blame_simple") do |repo, location|
      head = Fixture.seed(repo, location)

      stream = Git::Stream.new(repo)
      slot   = stream.blame("seed.txt")
      stream.run.error.should be_nil
      stream.seal

      entries = stream[slot].as(Array(Git::BlameEntry))
      entries.size.should eq(1)
      entries[0].commit.should eq(head)
      entries[0].final_start_line.should eq(1_u64)
      entries[0].lines.should eq(1_u64)
      entries[0].author.should eq("Spec Runner")
      entries[0].summary.should eq("seed")
    end
  end

  it "attributes lines to their commits" do
    Fixture.with_repo("blame_two") do |repo, location|
      first  = Fixture.seed(repo, location)
      second = Fixture.commit(repo, location, "seed.txt", "seed\nmore\n", "more")

      stream = Git::Stream.new(repo)
      slot   = stream.blame("seed.txt")
      stream.run.error.should be_nil
      stream.seal

      entries = stream[slot].as(Array(Git::BlameEntry))
      entries.size.should eq(2)
      entries.sum(&.lines).should eq(2_u64)
      entries[0].commit.should eq(first)
      entries[1].commit.should eq(second)
      entries[1].final_start_line.should eq(2_u64)
    end
  end

  it "limits the blamed line range" do
    Fixture.with_repo("blame_range") do |repo, location|
      Fixture.seed(repo, location)
      second = Fixture.commit(repo, location, "seed.txt", "seed\nmore\n", "more")

      stream = Git::Stream.new(repo)
      slot   = stream.blame("seed.txt", min_line: 2, max_line: 2)
      stream.run.error.should be_nil
      stream.seal

      entries = stream[slot].as(Array(Git::BlameEntry))
      entries.size.should eq(1)
      entries[0].commit.should eq(second)
    end
  end

  it "fails on an unknown path" do
    Fixture.with_repo("blame_missing") do |repo, location|
      Fixture.seed(repo, location)

      stream = Git::Stream.new(repo)
      stream.blame("missing.txt")
      stream.run.error.should be_a(Git::Err)
    end
  end
end
