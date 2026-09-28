# spec/remote_spec.cr
require "./spec_helper"

describe "remote" do
  after_each { Fixture.cleanup }

  it "adds and lists a remote" do
    Fixture.with_repo("remote_add") do |repo, location|
      Fixture.seed(repo, location)

      stream = Git::Stream.new(repo)
      stream.remote_add("origin", "https://example.com/repo.git")
      list = stream.remote_list
      url  = stream.config_get("remote.origin.url")
      stream.run.error.should be_nil
      stream.seal

      stream[list].as(Array(String)).should contain("origin")
      stream[url].should eq("https://example.com/repo.git")
    end
  end

  it "removes a remote" do
    Fixture.with_repo("remote_remove") do |repo, location|
      Fixture.seed(repo, location)

      setup = Git::Stream.new(repo)
      setup.remote_add("origin", "https://example.com/repo.git")
      setup.run.error.should be_nil
      setup.seal

      stream = Git::Stream.new(repo)
      stream.remote_remove("origin")
      list = stream.remote_list
      stream.run.error.should be_nil
      stream.seal

      stream[list].as(Array(String)).should be_empty
    end
  end

  it "fails to add a duplicate remote" do
    Fixture.with_repo("remote_duplicate") do |repo, location|
      Fixture.seed(repo, location)

      setup = Git::Stream.new(repo)
      setup.remote_add("origin", "https://example.com/repo.git")
      setup.run.error.should be_nil
      setup.seal

      stream = Git::Stream.new(repo)
      stream.remote_add("origin", "https://example.com/other.git")
      stream.run.error.should be_a(Git::Err)
    end
  end

  it "rolls back an added remote" do
    Fixture.with_repo("remote_rollback_add") do |repo, location|
      Fixture.seed(repo, location)

      stream = Git::Stream.new(repo)
      stream.remote_add("origin", "https://example.com/repo.git")
      stream.run.error.should be_nil
      stream.rollback.should be_nil
      stream.seal

      check = Git::Stream.new(repo)
      list  = check.remote_list
      check.run.error.should be_nil
      check.seal

      check[list].as(Array(String)).should be_empty
    end
  end

  it "rolls back a removed remote with its url" do
    Fixture.with_repo("remote_rollback_remove") do |repo, location|
      Fixture.seed(repo, location)

      setup = Git::Stream.new(repo)
      setup.remote_add("origin", "https://example.com/repo.git")
      setup.run.error.should be_nil
      setup.seal

      stream = Git::Stream.new(repo)
      stream.remote_remove("origin")
      stream.run.error.should be_nil
      stream.rollback.should be_nil
      stream.seal

      check = Git::Stream.new(repo)
      url   = check.config_get("remote.origin.url")
      check.run.error.should be_nil
      check.seal

      check[url].should eq("https://example.com/repo.git")
    end
  end

  it "fetches from a local remote" do
    Fixture.with_repo("remote_fetch_source") do |source, source_location|
      head = Fixture.seed(source, source_location)

      Fixture.with_repo("remote_fetch_target") do |repo, location|
        Fixture.seed(repo, location)

        stream = Git::Stream.new(repo, allow_irreversible: true)
        stream.remote_add("origin", source_location)
        stream.fetch("origin")
        stream.run.error.should be_nil
        stream.seal

        check = Git::Stream.new(repo)
        base  = check.merge_base("HEAD", "refs/remotes/origin/master")
        check.run.error.should be_nil
        check.seal

        check[base].as(Git::Oid).should eq(head)
      end
    end
  end
end
