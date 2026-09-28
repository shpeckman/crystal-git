# spec/describe_spec.cr
require "./spec_helper"

describe "describe" do
  after_each { Fixture.cleanup }

  it "names a tagged commit exactly" do
    Fixture.with_repo("describe_exact") do |repo, location|
      Fixture.seed(repo, location)

      tag = Git::Stream.new(repo)
      tag.tag("v1.0", message: "release")
      tag.run.error.should be_nil
      tag.seal

      stream = Git::Stream.new(repo)
      text   = stream.describe
      stream.run.error.should be_nil
      stream.seal

      stream[text].should eq("v1.0")
    end
  end

  it "includes distance and abbreviated id past a tag" do
    Fixture.with_repo("describe_distance") do |repo, location|
      first = Fixture.seed(repo, location)

      tag = Git::Stream.new(repo)
      tag.tag("v1.0", message: "release")
      tag.run.error.should be_nil
      tag.seal

      head = Fixture.commit(repo, location, "seed.txt", "more\n", "second")

      stream = Git::Stream.new(repo)
      text   = stream.describe
      stream.run.error.should be_nil
      stream.seal

      stream[text].should eq("v1.0-1-g#{head.hex[0, 7]}")

      exact = Git::Stream.new(repo)
      long  = exact.describe("#{first.hex[0, 8]}", long: true)
      exact.run.error.should be_nil
      exact.seal

      exact[long].should eq("v1.0-0-g#{first.hex[0, 7]}")
    end
  end

  it "falls back to the commit id with always" do
    Fixture.with_repo("describe_always") do |repo, location|
      head = Fixture.seed(repo, location)

      stream = Git::Stream.new(repo)
      plain  = stream.describe
      always = stream.describe(always: true)
      stream.run.error.should_not be_nil

      fallback = Git::Stream.new(repo)
      text     = fallback.describe(always: true)
      fallback.run.error.should be_nil
      fallback.seal

      fallback[text].should eq(head.hex[0, 7])
    end
  end

  it "describes an arbitrary target" do
    Fixture.with_repo("describe_target") do |repo, location|
      first = Fixture.seed(repo, location)

      tag = Git::Stream.new(repo)
      tag.tag("v1.0", first.hex, message: "release")
      tag.run.error.should be_nil
      tag.seal

      Fixture.commit(repo, location, "seed.txt", "more\n", "second")

      stream = Git::Stream.new(repo)
      text   = stream.describe(first.hex)
      stream.run.error.should be_nil
      stream.seal

      stream[text].should eq("v1.0")
    end
  end

  it "marks a dirty workdir" do
    Fixture.with_repo("describe_dirty") do |repo, location|
      Fixture.seed(repo, location)

      tag = Git::Stream.new(repo)
      tag.tag("v1.0", message: "release")
      tag.run.error.should be_nil
      tag.seal

      Fixture.write(location, "seed.txt", "dirty\n")

      stream = Git::Stream.new(repo)
      clean  = stream.describe
      dirty  = stream.describe(dirty: true)
      stream.run.error.should be_nil
      stream.seal

      stream[clean].should eq("v1.0")
      stream[dirty].should eq("v1.0-dirty")
    end
  end

  it "considers lightweight tags only when asked" do
    Fixture.with_repo("describe_lightweight") do |repo, location|
      Fixture.seed(repo, location)

      tag = Git::Stream.new(repo)
      tag.tag("v1.0")
      tag.run.error.should be_nil
      tag.seal

      fallback = Git::Stream.new(repo)
      always   = fallback.describe(always: true)
      fallback.run.error.should be_nil
      fallback.seal
      fallback[always].should_not eq("v1.0")

      stream = Git::Stream.new(repo)
      tagged = stream.describe(tags: true)
      all    = stream.describe(all: true)
      stream.run.error.should be_nil
      stream.seal

      stream[tagged].should eq("v1.0")
      stream[all].should eq("tags/v1.0")
    end
  end
end
