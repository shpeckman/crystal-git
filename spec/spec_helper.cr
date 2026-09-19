# spec/spec_helper.cr
require "spec"
require "file_utils"
require "../src/crystal-git"

Spec.before_suite do
  LibGit2.libgit2_init
end

Spec.after_suite do
  LibGit2.libgit2_shutdown
end

module Fixture
  ROOT   = "./tmp_stream_specs"
  BRANCH = "master"

  def self.path(name : String) : String
    File.join(ROOT, name)
  end

  def self.with_repo(name : String, bare : Bool = false, & : Git::Repo, String ->)
    location = path(name)
    FileUtils.rm_rf(location)
    FileUtils.mkdir_p(ROOT)

    result = Git::Repo.init(location, bare)
    result.should be_a(Git::Ok(Git::Repo))
    repo = result.as(Git::Ok(Git::Repo)).value

    identify(repo)

    begin
      yield repo, location
    ensure
      repo.close
      FileUtils.rm_rf(location)
    end
  end

  def self.identify(repo : Git::Repo) : Nil
    config = uninitialized LibGit2::Config
    LibGit2.repository_config(pointerof(config), repo.handle).should eq(0)
    LibGit2.config_set_string(config, "user.name", "Spec Runner").should eq(0)
    LibGit2.config_set_string(config, "user.email", "spec@example.com").should eq(0)
    LibGit2.config_free(config)

    LibGit2.repository_set_head(repo.handle, "refs/heads/#{BRANCH}").should eq(0)
  end

  def self.write(location : String, path : String, content : String) : Nil
    full = File.join(location, path)
    FileUtils.mkdir_p(File.dirname(full))
    File.write(full, content)
  end

  def self.seed(repo : Git::Repo, location : String, message : String = "seed") : Git::Oid
    write(location, "seed.txt", "seed\n")
    stream = Git::Stream.new(repo)
    stream.stage("seed.txt")
    slot   = stream.commit(message)
    report = stream.run
    report.error.should be_nil
    stream.seal
    oid = stream[slot]
    oid.should_not be_nil
    oid.as(Git::Oid)
  end

  def self.commit(repo : Git::Repo, location : String, path : String, content : String, message : String) : Git::Oid
    write(location, path, content)
    stream = Git::Stream.new(repo)
    stream.stage(path)
    slot   = stream.commit(message)
    report = stream.run
    report.error.should be_nil
    stream.seal
    oid = stream[slot]
    oid.should_not be_nil
    oid.as(Git::Oid)
  end

  def self.state(repo : Git::Repo) : Git::State
    Git::State.from_native(LibGit2.repository_state(repo.handle))
  end

  def self.head(repo : Git::Repo) : Git::Oid
    result = repo.head_oid
    result.should be_a(Git::Ok(Git::Oid))
    result.as(Git::Ok(Git::Oid)).value
  end

  def self.branch_names(repo : Git::Repo) : Array(String)
    stream = Git::Stream.new(repo)
    slot   = stream.list_branches
    stream.run.error.should be_nil
    stream.seal
    names = stream[slot]
    names.should_not be_nil
    names.as(Array(String))
  end

  def self.cleanup : Nil
    FileUtils.rm_rf(ROOT)
  end
end
