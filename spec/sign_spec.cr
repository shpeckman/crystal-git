# spec/sign_spec.cr
require "./spec_helper"

describe "signed commits" do
  after_each { Fixture.cleanup }

  it "creates a commit with an embedded signature" do
    Fixture.with_repo("sign_commit") do |repo, location|
      Fixture.seed(repo, location)
      Fixture.write(location, "seed.txt", "signed\n")

      stream = Git::Stream.new(repo)
      stream.stage("seed.txt")
      slot = stream.commit("signed commit", signer: ->(content : String) { "FAKE-SIGNATURE" })
      stream.run.error.should be_nil
      stream.seal

      oid = stream[slot].as(Git::Oid)
      Fixture.head(repo).should eq(oid)

      read = Git::Stream.new(repo)
      data = read.read_object(oid.hex)
      read.run.error.should be_nil
      read.seal

      text = read[data].as(Git::ObjectData).text
      text.should contain("gpgsig")
      text.should contain("FAKE-SIGNATURE")
      text.should contain("signed commit")
    end
  end

  it "creates an initial signed commit on an unborn head" do
    Fixture.with_repo("sign_initial") do |repo, location|
      Fixture.write(location, "first.txt", "one\n")

      stream = Git::Stream.new(repo)
      stream.stage("first.txt")
      slot = stream.commit("initial", signer: ->(content : String) { "FAKE-SIGNATURE" })
      stream.run.error.should be_nil
      stream.seal

      oid = stream[slot].as(Git::Oid)
      Fixture.head(repo).should eq(oid)
    end
  end

  it "passes the commit content to the signer" do
    Fixture.with_repo("sign_content") do |repo, location|
      Fixture.seed(repo, location)
      Fixture.write(location, "seed.txt", "signed\n")

      seen   = nil.as(String?)
      stream = Git::Stream.new(repo)
      stream.stage("seed.txt")
      slot = stream.commit("check content", signer: ->(content : String) {
        seen = content
        "SIG"
      })
      stream.run.error.should be_nil
      stream.seal

      content = seen.not_nil!
      content.should contain("tree ")
      content.should contain("author Spec Runner")
      content.should contain("check content")
    end
  end
end
