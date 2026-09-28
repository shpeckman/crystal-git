# spec/mailmap_spec.cr
require "./spec_helper"

describe "mailmap" do
  after_each { Fixture.cleanup }

  it "resolves mapped identities" do
    Fixture.with_repo("mailmap_mapped") do |repo, location|
      Fixture.seed(repo, location)
      Fixture.write(location, ".mailmap", "Real Name <real@example.com> <old@example.com>\n")

      stream   = Git::Stream.new(repo)
      resolved = stream.mailmap_resolve("Whatever", "old@example.com")
      stream.run.error.should be_nil
      stream.seal

      identity = stream[resolved].as(Git::Identity)
      identity.name.should eq("Real Name")
      identity.email.should eq("real@example.com")
    end
  end

  it "passes through unmapped identities" do
    Fixture.with_repo("mailmap_plain") do |repo, location|
      Fixture.seed(repo, location)

      stream   = Git::Stream.new(repo)
      resolved = stream.mailmap_resolve("Spec Runner", "spec@example.com")
      stream.run.error.should be_nil
      stream.seal

      stream[resolved].should eq(Git::Identity.new("Spec Runner", "spec@example.com"))
    end
  end
end
