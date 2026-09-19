# spec/stream_spec.cr
require "./spec_helper"

describe Git::Stream do
  after_each { Fixture.cleanup }

  it "starts in the building phase" do
    Fixture.with_repo("stream_phase") do |repo, _|
      stream = Git::Stream.new(repo)
      stream.phase.should eq(Git::Stream::Phase::Building)
      stream.size.should eq(0)
    end
  end

  it "refuses to validate an empty queue" do
    Fixture.with_repo("stream_empty") do |repo, _|
      Git::Stream.new(repo).validate.should be_a(Git::Err)
    end
  end

  it "queues commands and reports the plan" do
    Fixture.with_repo("stream_plan") do |repo, location|
      Fixture.write(location, "a.txt", "a\n")

      stream = Git::Stream.new(repo)
      stream.stage("a.txt")
      stream.commit("first")

      result = stream.validate
      result.should be_a(Git::Ok(Git::Stream::Plan))

      plan = result.as(Git::Ok(Git::Stream::Plan)).value
      plan.size.should eq(2)
      plan.mode.should eq(Git::Stream::RollbackMode::UndoLog)
      plan.irreversible.should be_false
      stream.phase.should eq(Git::Stream::Phase::Validated)
    end
  end

  it "exposes slot values after a successful run" do
    Fixture.with_repo("stream_slots") do |repo, location|
      Fixture.write(location, "a.txt", "a\n")

      stream = Git::Stream.new(repo)
      count  = stream.stage("a.txt")
      oid    = stream.commit("first")

      report = stream.run
      report.error.should be_nil
      report.size.should eq(2)
      stream.phase.should eq(Git::Stream::Phase::Completed)

      stream[count].should eq(1_u64)
      stream[oid].should_not be_nil
      stream.seal
      stream[oid].should_not be_nil
    end
  end

  it "steps one command at a time" do
    Fixture.with_repo("stream_step") do |repo, location|
      Fixture.write(location, "a.txt", "a\n")

      stream = Git::Stream.new(repo)
      stream.stage("a.txt")
      stream.commit("first")

      first = stream.step
      first.should be_a(Git::Ok(Git::Value))
      stream.phase.should eq(Git::Stream::Phase::Running)

      second = stream.step
      second.should be_a(Git::Ok(Git::Value))
      stream.phase.should eq(Git::Stream::Phase::Completed)

      stream.step.should be_nil
      stream.seal
    end
  end

  it "rejects commands queued after the run has started" do
    Fixture.with_repo("stream_late") do |repo, location|
      Fixture.write(location, "a.txt", "a\n")

      stream = Git::Stream.new(repo)
      stream.stage("a.txt")
      stream.step

      slot = stream.commit("late")
      slot.valid?.should be_false
      stream.validate.should be_a(Git::Err)
      stream.seal
    end
  end

  it "halts on the first failure and leaves the rest unexecuted" do
    Fixture.with_repo("stream_halt") do |repo, location|
      Fixture.seed(repo, location)
      Fixture.write(location, "a.txt", "a\n")

      stream = Git::Stream.new(repo)
      stream.stage("a.txt")
      stream.create_branch("does-not-resolve", "refs/heads/missing")
      last = stream.commit("never runs")

      report = stream.run
      report.error.should_not be_nil
      report.size.should eq(2)
      stream.phase.should eq(Git::Stream::Phase::Halted)
      stream[last].should be_nil

      stream.rollback.should be_nil
      stream.seal
    end
  end

  it "refuses to step again after halting" do
    Fixture.with_repo("stream_resume") do |repo, location|
      Fixture.seed(repo, location)

      stream = Git::Stream.new(repo)
      stream.delete_branch("nonexistent")

      stream.run.error.should_not be_nil
      stream.step.should be_a(Git::Err)
      stream.seal
    end
  end

  it "rejects commands that are illegal in the current repository state" do
    Fixture.with_repo("stream_state") do |repo, location|
      base = Fixture.seed(repo, location)

      create = Git::Stream.new(repo)
      create.create_branch("topic", base.hex)
      create.run.error.should be_nil
      create.seal

      checkout = Git::Stream.new(repo)
      checkout.checkout("topic")
      checkout.run.error.should be_nil
      checkout.seal

      Fixture.commit(repo, location, "topic.txt", "topic\n", "topic work")

      back = Git::Stream.new(repo)
      back.checkout(Fixture::BRANCH)
      back.run.error.should be_nil
      back.seal

      Fixture.commit(repo, location, "main.txt", "main\n", "main work")

      merge   = Git::Stream.new(repo)
      outcome = merge.merge("topic")
      merge.run.error.should be_nil
      merge.seal

      merge[outcome].should eq(Git::MergeOutcome::Merged)
      Fixture.state(repo).should eq(Git::State::Merge)

      blocked = Git::Stream.new(repo)
      blocked.checkout("topic")

      result = blocked.validate
      result.should be_a(Git::Err)
      result.as(Git::Err).message.should contain("Merge")
    end
  end

  it "blocks commands whose predicates are unmet" do
    Fixture.with_repo("stream_predicate") do |repo, _|
      stream = Git::Stream.new(repo)
      stream.commit("nothing staged")

      result = stream.validate
      result.should be_a(Git::Err)
      result.as(Git::Err).message.should contain("commit")
    end
  end

  it "blocks worktree commands on a bare repository" do
    Fixture.with_repo("stream_bare", bare: true) do |repo, _|
      stream = Git::Stream.new(repo)
      stream.checkout("HEAD")

      stream.validate.should be_a(Git::Err)
    end
  end
end
