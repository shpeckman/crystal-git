# spec/clone_spec.cr
require "./spec_helper"

describe "clone" do
  after_each { Fixture.cleanup }

  it "clones a local repository" do
    Fixture.with_repo("clone_source") do |source, source_location|
      head = Fixture.seed(source, source_location)

      destination = Fixture.path("clone_target")
      FileUtils.rm_rf(destination)

      result = Git::Repo.clone(source_location, destination)
      result.should be_a(Git::Ok(Git::Repo))

      repo = result.as(Git::Ok(Git::Repo)).value
      begin
        repo.head_oid.as(Git::Ok(Git::Oid)).value.should eq(head)
        File.exists?(File.join(destination, "seed.txt")).should be_true
      ensure
        repo.close
      end
    end
  end

  it "clones with the block form" do
    Fixture.with_repo("clone_block_source") do |source, source_location|
      head = Fixture.seed(source, source_location)

      destination = Fixture.path("clone_block_target")
      FileUtils.rm_rf(destination)

      Git::Repo.clone(source_location, destination) do |repo|
        repo.closed?.should be_false
        repo.head_oid.as(Git::Ok(Git::Oid)).value.should eq(head)
      end
    end
  end

  it "clones a bare repository" do
    Fixture.with_repo("clone_bare_source") do |source, source_location|
      Fixture.seed(source, source_location)

      destination = Fixture.path("clone_bare_target")
      FileUtils.rm_rf(destination)

      result = Git::Repo.clone(source_location, destination, bare: true)
      result.should be_a(Git::Ok(Git::Repo))

      repo = result.as(Git::Ok(Git::Repo)).value
      begin
        conditions = repo.conditions.as(Git::Ok(Git::Conditions)).value
        conditions.predicates.bare?.should be_true
        File.exists?(File.join(destination, "seed.txt")).should be_false
      ensure
        repo.close
      end
    end
  end

  it "reports an error for a missing source" do
    destination = Fixture.path("clone_missing_target")
    FileUtils.rm_rf(destination)

    result = Git::Repo.clone(Fixture.path("does_not_exist"), destination)
    result.should be_a(Git::Err)
  end
end
