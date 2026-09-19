# spec/conflict_spec.cr
require "./spec_helper"

private def diverge(repo : Git::Repo, location : String) : Nil
  Fixture.seed(repo, location)
  Fixture.commit(repo, location, "file.txt", "base\n", "base file")

  create = Git::Stream.new(repo)
  create.create_branch("topic", "HEAD")
  create.run.error.should be_nil
  create.seal

  Fixture.commit(repo, location, "file.txt", "ours\n", "our edit")

  checkout = Git::Stream.new(repo)
  checkout.checkout("topic")
  checkout.run.error.should be_nil
  checkout.seal

  Fixture.commit(repo, location, "file.txt", "theirs\n", "their edit")

  back = Git::Stream.new(repo)
  back.checkout(Fixture::BRANCH)
  back.run.error.should be_nil
  back.seal
end

private def conflict(repo : Git::Repo, location : String) : Nil
  diverge(repo, location)

  merge   = Git::Stream.new(repo)
  outcome = merge.merge("topic")
  merge.run.error.should be_nil
  merge.seal

  merge[outcome].should eq(Git::MergeOutcome::Conflicted)
end

describe "conflict commands" do
  after_each { Fixture.cleanup }

  it "lists conflicted paths with both sides" do
    Fixture.with_repo("conflict_list") do |repo, location|
      conflict(repo, location)

      stream = Git::Stream.new(repo)
      slot   = stream.conflicts
      stream.run.error.should be_nil
      stream.seal

      entries = stream[slot].as(Array(Git::ConflictEntry))
      entries.size.should eq(1)

      entry = entries.first
      entry.path.should eq("file.txt")
      entry.ancestor.should_not be_nil
      entry.ours.should_not be_nil
      entry.theirs.should_not be_nil
      entry.deleted_by_us?.should be_false
    end
  end

  it "resolves a conflict in favour of our side" do
    Fixture.with_repo("conflict_ours") do |repo, location|
      conflict(repo, location)

      stream = Git::Stream.new(repo, allow_irreversible: true)
      slot   = stream.resolve_all(:ours)
      stream.run.error.should be_nil
      stream.seal

      stream[slot].should eq(1)
      File.read(File.join(location, "file.txt")).should eq("ours\n")
      repo.conditions.as(Git::Ok(Git::Conditions)).value.predicates.conflicted?.should be_false
    end
  end

  it "resolves a conflict in favour of their side" do
    Fixture.with_repo("conflict_theirs") do |repo, location|
      conflict(repo, location)

      stream = Git::Stream.new(repo, allow_irreversible: true)
      stream.resolve("file.txt", :theirs)
      stream.run.error.should be_nil
      stream.seal

      File.read(File.join(location, "file.txt")).should eq("theirs\n")
    end
  end

  it "resolves a conflict by unioning both sides" do
    Fixture.with_repo("conflict_union") do |repo, location|
      conflict(repo, location)

      stream = Git::Stream.new(repo, allow_irreversible: true)
      stream.resolve_all(:union)
      stream.run.error.should be_nil
      stream.seal

      content = File.read(File.join(location, "file.txt"))
      content.should contain("ours")
      content.should contain("theirs")
      content.should_not contain("<<<<<<<")
    end
  end

  it "commits a resolved merge with two parents" do
    Fixture.with_repo("conflict_commit") do |repo, location|
      conflict(repo, location)

      resolve = Git::Stream.new(repo, allow_irreversible: true)
      resolve.resolve_all(:ours)
      resolve.run.error.should be_nil
      resolve.seal

      finish = Git::Stream.new(repo)
      slot   = finish.commit("merge topic")
      finish.run.error.should be_nil
      finish.seal

      oid = finish[slot].as(Git::Oid)
      raw = oid.raw
      commit = uninitialized LibGit2::Commit
      LibGit2.commit_lookup(pointerof(commit), repo.handle, pointerof(raw)).should eq(0)
      LibGit2.commit_parentcount(commit).should eq(2_u32)
      LibGit2.commit_free(commit)

      Fixture.state(repo).should eq(Git::State::Clean)
    end
  end

  it "blocks resolve when the index has no conflicts" do
    Fixture.with_repo("conflict_none") do |repo, location|
      Fixture.seed(repo, location)

      stream = Git::Stream.new(repo, allow_irreversible: true)
      stream.resolve_all(:ours)

      stream.validate.should be_a(Git::Err)
    end
  end

  it "aborts a conflicted merge" do
    Fixture.with_repo("conflict_abort") do |repo, location|
      conflict(repo, location)

      stream = Git::Stream.new(repo, allow_irreversible: true)
      stream.abort_integration
      stream.run.error.should be_nil
      stream.seal

      Fixture.state(repo).should eq(Git::State::Clean)
      File.read(File.join(location, "file.txt")).should eq("ours\n")
      repo.conditions.as(Git::Ok(Git::Conditions)).value.predicates.conflicted?.should be_false
    end
  end
end

describe "rebase conflicts" do
  after_each { Fixture.cleanup }

  it "stops at a conflict and leaves the rebase open" do
    Fixture.with_repo("rebase_stop") do |repo, location|
      diverge(repo, location)

      checkout = Git::Stream.new(repo)
      checkout.checkout("topic")
      checkout.run.error.should be_nil
      checkout.seal

      stream = Git::Stream.new(repo)
      stream.rebase(Fixture::BRANCH)

      report = stream.run
      report.error.should_not be_nil
      report.error.as(Git::Err).message.should contain("resolve them")
      stream.seal

      Git::Commands::REBASE_STATES.includes?(Fixture.state(repo).to_set).should be_true
      repo.conditions.as(Git::Ok(Git::Conditions)).value.predicates.conflicted?.should be_true
    end
  end

  it "resolves and continues a stopped rebase" do
    Fixture.with_repo("rebase_continue") do |repo, location|
      diverge(repo, location)

      checkout = Git::Stream.new(repo)
      checkout.checkout("topic")
      checkout.run.error.should be_nil
      checkout.seal

      stopped = Git::Stream.new(repo)
      stopped.rebase(Fixture::BRANCH)
      stopped.run.error.should_not be_nil
      stopped.seal

      resolve = Git::Stream.new(repo, allow_irreversible: true)
      resolve.resolve_all(:theirs)
      resolve.run.error.should be_nil
      resolve.seal

      stream = Git::Stream.new(repo, allow_irreversible: true)
      slot   = stream.continue_rebase
      stream.run.error.should be_nil
      stream.seal

      stream[slot].should eq(1_u64)
      Fixture.state(repo).should eq(Git::State::Clean)
      File.read(File.join(location, "file.txt")).should eq("theirs\n")
    end
  end

  it "aborts a stopped rebase" do
    Fixture.with_repo("rebase_abort_conflict") do |repo, location|
      diverge(repo, location)

      checkout = Git::Stream.new(repo)
      checkout.checkout("topic")
      checkout.run.error.should be_nil
      checkout.seal

      before = Fixture.head(repo)

      stopped = Git::Stream.new(repo)
      stopped.rebase(Fixture::BRANCH)
      stopped.run.error.should_not be_nil
      stopped.seal

      stream = Git::Stream.new(repo, allow_irreversible: true)
      stream.abort_rebase
      stream.run.error.should be_nil
      stream.seal

      Fixture.state(repo).should eq(Git::State::Clean)
      Fixture.head(repo).should eq(before)
      File.read(File.join(location, "file.txt")).should eq("theirs\n")
    end
  end
end
