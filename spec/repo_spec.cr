# spec/repo_spec.cr
require "./spec_helper"

describe Git::Repo do
  after_each { Fixture.cleanup }

  it "initializes a repository and reports its conditions" do
    Fixture.with_repo("repo_init") do |repo, _|
      result = repo.conditions
      result.should be_a(Git::Ok(Git::Conditions))

      conditions = result.as(Git::Ok(Git::Conditions)).value
      conditions.state.should eq(Git::State::Clean)
      conditions.predicates.unborn_head?.should be_true
      conditions.predicates.bare?.should be_false
      conditions.predicates.dirty_index?.should be_false
    end
  end

  it "reports a bare repository" do
    Fixture.with_repo("repo_bare", bare: true) do |repo, _|
      conditions = repo.conditions.as(Git::Ok(Git::Conditions)).value
      conditions.predicates.bare?.should be_true
    end
  end

  it "returns an error when opening a missing repository" do
    Git::Repo.open("./does_not_exist_at_all").should be_a(Git::Err)
  end

  it "caches the index handle across calls" do
    Fixture.with_repo("repo_index") do |repo, _|
      first  = repo.index.as(Git::Ok(LibGit2::Index)).value
      second = repo.index.as(Git::Ok(LibGit2::Index)).value

      first.should eq(second)
    end
  end

  it "detects a dirty index after staging" do
    Fixture.with_repo("repo_dirty") do |repo, location|
      Fixture.write(location, "a.txt", "a\n")

      stream = Git::Stream.new(repo)
      stream.stage("a.txt")
      stream.run.error.should be_nil
      stream.seal

      conditions = repo.conditions.as(Git::Ok(Git::Conditions)).value
      conditions.predicates.dirty_index?.should be_true
    end
  end

  it "resolves HEAD after a commit" do
    Fixture.with_repo("repo_head") do |repo, location|
      oid = Fixture.seed(repo, location)

      Fixture.head(repo).should eq(oid)
      repo.head_symbolic_name.as(Git::Ok(String)).value.should eq("refs/heads/master")
    end
  end

  it "reports closure once" do
    result = Git::Repo.init(Fixture.path("repo_close"))
    repo   = result.as(Git::Ok(Git::Repo)).value

    repo.closed?.should be_false
    repo.close
    repo.closed?.should be_true
    repo.close

    Fixture.cleanup
  end
end
