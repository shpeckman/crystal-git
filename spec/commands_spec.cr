# spec/commands_spec.cr
require "./spec_helper"

describe "index commands" do
  after_each { Fixture.cleanup }

  it "stages files and reports the entry count" do
    Fixture.with_repo("cmd_stage") do |repo, location|
      Fixture.write(location, "a.txt", "a\n")
      Fixture.write(location, "b.txt", "b\n")

      stream = Git::Stream.new(repo)
      count  = stream.stage(["a.txt", "b.txt"])

      stream.run.error.should be_nil
      stream[count].should eq(2_u64)
      stream.seal
    end
  end

  it "unstages a path back to HEAD" do
    Fixture.with_repo("cmd_unstage") do |repo, location|
      Fixture.seed(repo, location)
      Fixture.write(location, "extra.txt", "extra\n")

      stage = Git::Stream.new(repo)
      stage.stage("extra.txt")
      stage.run.error.should be_nil
      stage.seal

      stream = Git::Stream.new(repo)
      stream.unstage("extra.txt")
      stream.run.error.should be_nil
      stream.seal

      repo.conditions.as(Git::Ok(Git::Conditions)).value.predicates.dirty_index?.should be_false
    end
  end

  it "removes tracked paths from the index and worktree" do
    Fixture.with_repo("cmd_remove") do |repo, location|
      Fixture.seed(repo, location)
      Fixture.commit(repo, location, "gone.txt", "gone\n", "add gone")

      stream = Git::Stream.new(repo)
      slot   = stream.remove("gone.txt")
      stream.run.error.should be_nil
      stream.seal

      stream[slot].should eq(1_u64)
      File.exists?(File.join(location, "gone.txt")).should be_false

      index = repo.index.as(Git::Ok(LibGit2::Index)).value
      LibGit2.index_get_bypath(index, "gone.txt", 0).null?.should be_true
    end
  end
end

describe "history commands" do
  after_each { Fixture.cleanup }

  it "commits with HEAD as the parent" do
    Fixture.with_repo("cmd_commit") do |repo, location|
      first  = Fixture.seed(repo, location)
      second = Fixture.commit(repo, location, "b.txt", "b\n", "second")

      raw = second.raw
      commit = uninitialized LibGit2::Commit
      LibGit2.commit_lookup(pointerof(commit), repo.handle, pointerof(raw)).should eq(0)
      LibGit2.commit_parentcount(commit).should eq(1_u32)
      Git::Oid.from(LibGit2.commit_parent_id(commit, 0_u32)).should eq(first)
      LibGit2.commit_free(commit)
    end
  end

  it "checks out a branch and reattaches HEAD" do
    Fixture.with_repo("cmd_checkout") do |repo, location|
      base = Fixture.seed(repo, location)

      create = Git::Stream.new(repo)
      create.create_branch("topic", base.hex)
      create.run.error.should be_nil
      create.seal

      stream = Git::Stream.new(repo)
      slot   = stream.checkout("topic")
      stream.run.error.should be_nil

      stream[slot].should eq("refs/heads/topic")
      repo.head_symbolic_name.as(Git::Ok(String)).value.should eq("refs/heads/topic")
      stream.seal
    end
  end

  it "resets hard back to an earlier commit" do
    Fixture.with_repo("cmd_reset") do |repo, location|
      first = Fixture.seed(repo, location)
      Fixture.commit(repo, location, "b.txt", "b\n", "second")

      stream = Git::Stream.new(repo)
      slot   = stream.reset(first.hex, Git::ResetMode::Hard)
      stream.run.error.should be_nil

      stream[slot].should eq(first)
      Fixture.head(repo).should eq(first)
      File.exists?(File.join(location, "b.txt")).should be_false
      stream.seal
    end
  end

  it "sets HEAD to another ref without touching the worktree" do
    Fixture.with_repo("cmd_set_head") do |repo, location|
      base = Fixture.seed(repo, location)

      create = Git::Stream.new(repo)
      create.create_branch("topic", base.hex)
      create.run.error.should be_nil
      create.seal

      stream = Git::Stream.new(repo)
      stream.set_head("refs/heads/topic")
      stream.run.error.should be_nil
      stream.seal

      repo.head_symbolic_name.as(Git::Ok(String)).value.should eq("refs/heads/topic")
    end
  end
end

describe "ref commands" do
  after_each { Fixture.cleanup }

  it "creates, moves, and deletes a branch" do
    Fixture.with_repo("cmd_branch") do |repo, location|
      base = Fixture.seed(repo, location)

      create  = Git::Stream.new(repo)
      created = create.create_branch("topic", base.hex)
      create.run.error.should be_nil
      create.seal
      create[created].should eq(base)

      move  = Git::Stream.new(repo)
      moved = move.move_branch("topic", "feature")
      move.run.error.should be_nil
      move.seal
      move[moved].should eq("refs/heads/feature")

      Fixture.branch_names(repo).should contain("feature")

      remove  = Git::Stream.new(repo)
      removed = remove.delete_branch("feature")
      remove.run.error.should be_nil
      remove.seal
      remove[removed].should eq("refs/heads/feature")

      Fixture.branch_names(repo).should_not contain("feature")
    end
  end

  it "refuses to delete the checked out branch" do
    Fixture.with_repo("cmd_branch_head") do |repo, location|
      Fixture.seed(repo, location)

      stream = Git::Stream.new(repo)
      stream.delete_branch(Fixture::BRANCH)

      report = stream.run
      report.error.should_not be_nil
      report.error.as(Git::Err).message.should contain("checked out")
      stream.seal
    end
  end

  it "creates lightweight and annotated tags" do
    Fixture.with_repo("cmd_tag") do |repo, location|
      head = Fixture.seed(repo, location)

      light = Git::Stream.new(repo)
      slot  = light.tag("v1")
      light.run.error.should be_nil
      light.seal
      light[slot].should eq(head)

      annotated = Git::Stream.new(repo)
      annotated.tag("v2", "HEAD", message: "release two")
      annotated.run.error.should be_nil
      annotated.seal

      stream = Git::Stream.new(repo)
      tags   = stream.list_tags
      stream.run.error.should be_nil
      stream.seal

      names = stream[tags].as(Array(String))
      names.should contain("v1")
      names.should contain("v2")
    end
  end

  it "deletes a tag" do
    Fixture.with_repo("cmd_tag_delete") do |repo, location|
      Fixture.seed(repo, location)

      create = Git::Stream.new(repo)
      create.tag("v1")
      create.run.error.should be_nil
      create.seal

      stream = Git::Stream.new(repo)
      slot   = stream.delete_tag("v1")
      stream.run.error.should be_nil
      stream.seal

      stream[slot].should eq("refs/tags/v1")
    end
  end
end

describe "integration commands" do
  after_each { Fixture.cleanup }

  it "reports an up to date merge" do
    Fixture.with_repo("cmd_merge_uptodate") do |repo, location|
      base = Fixture.seed(repo, location)

      create = Git::Stream.new(repo)
      create.create_branch("topic", base.hex)
      create.run.error.should be_nil
      create.seal

      stream = Git::Stream.new(repo)
      slot   = stream.merge("topic")
      stream.run.error.should be_nil
      stream.seal

      stream[slot].should eq(Git::MergeOutcome::UpToDate)
    end
  end

  it "fast forwards when the target is a descendant" do
    Fixture.with_repo("cmd_merge_ff") do |repo, location|
      base = Fixture.seed(repo, location)

      create = Git::Stream.new(repo)
      create.create_branch("topic", base.hex)
      create.run.error.should be_nil
      create.seal

      checkout = Git::Stream.new(repo)
      checkout.checkout("topic")
      checkout.run.error.should be_nil
      checkout.seal

      ahead = Fixture.commit(repo, location, "topic.txt", "topic\n", "topic work")

      back = Git::Stream.new(repo)
      back.checkout(Fixture::BRANCH)
      back.run.error.should be_nil
      back.seal

      stream = Git::Stream.new(repo)
      slot   = stream.merge("topic")
      stream.run.error.should be_nil
      stream.seal

      stream[slot].should eq(Git::MergeOutcome::FastForward)
      Fixture.head(repo).should eq(ahead)
    end
  end

  it "cherry picks a commit onto the current branch" do
    Fixture.with_repo("cmd_cherry_pick") do |repo, location|
      base = Fixture.seed(repo, location)

      create = Git::Stream.new(repo)
      create.create_branch("topic", base.hex)
      create.run.error.should be_nil
      create.seal

      checkout = Git::Stream.new(repo)
      checkout.checkout("topic")
      checkout.run.error.should be_nil
      checkout.seal

      picked = Fixture.commit(repo, location, "topic.txt", "topic\n", "topic work")

      back = Git::Stream.new(repo)
      back.checkout(Fixture::BRANCH)
      back.run.error.should be_nil
      back.seal

      stream = Git::Stream.new(repo)
      slot   = stream.cherry_pick(picked.hex)
      stream.run.error.should be_nil
      stream.seal

      stream[slot].should eq(picked)
      File.exists?(File.join(location, "topic.txt")).should be_true
      Fixture.state(repo).should eq(Git::State::Cherrypick)
    end
  end

  it "reverts a commit and clears state on the follow up commit" do
    Fixture.with_repo("cmd_revert") do |repo, location|
      Fixture.seed(repo, location)
      target = Fixture.commit(repo, location, "gone.txt", "gone\n", "add gone")

      revert = Git::Stream.new(repo)
      revert.revert(target.hex)
      revert.run.error.should be_nil
      revert.seal

      File.exists?(File.join(location, "gone.txt")).should be_false
      Fixture.state(repo).should eq(Git::State::Revert)

      finish = Git::Stream.new(repo)
      finish.commit("revert gone")
      finish.run.error.should be_nil
      finish.seal

      Fixture.state(repo).should eq(Git::State::Clean)
    end
  end

  it "aborts an in progress integration" do
    Fixture.with_repo("cmd_abort") do |repo, location|
      Fixture.seed(repo, location)
      target = Fixture.commit(repo, location, "gone.txt", "gone\n", "add gone")

      revert = Git::Stream.new(repo)
      revert.revert(target.hex)
      revert.run.error.should be_nil
      revert.seal

      stream = Git::Stream.new(repo)
      slot   = stream.abort_integration
      stream.run.error.should be_nil
      stream.seal

      stream[slot].should eq(target)
      Fixture.state(repo).should eq(Git::State::Clean)
      File.exists?(File.join(location, "gone.txt")).should be_true
    end
  end

  it "rebases a branch onto its upstream" do
    Fixture.with_repo("cmd_rebase") do |repo, location|
      base = Fixture.seed(repo, location)

      create = Git::Stream.new(repo)
      create.create_branch("topic", base.hex)
      create.run.error.should be_nil
      create.seal

      Fixture.commit(repo, location, "main.txt", "main\n", "main work")

      checkout = Git::Stream.new(repo)
      checkout.checkout("topic")
      checkout.run.error.should be_nil
      checkout.seal

      Fixture.commit(repo, location, "topic.txt", "topic\n", "topic work")

      stream = Git::Stream.new(repo)
      slot   = stream.rebase(Fixture::BRANCH)
      stream.run.error.should be_nil
      stream.seal

      stream[slot].should eq(1_u64)
      Fixture.state(repo).should eq(Git::State::Clean)
      File.exists?(File.join(location, "main.txt")).should be_true
      File.exists?(File.join(location, "topic.txt")).should be_true
    end
  end
end

describe "stash commands" do
  after_each { Fixture.cleanup }

  it "saves and lists a stash" do
    Fixture.with_repo("cmd_stash") do |repo, location|
      Fixture.seed(repo, location)
      Fixture.write(location, "seed.txt", "changed\n")

      stage = Git::Stream.new(repo)
      stage.stage("seed.txt")
      stage.run.error.should be_nil
      stage.seal

      save  = Git::Stream.new(repo, allow_irreversible: true)
      saved = save.stash(message: "work in progress")
      save.run.error.should be_nil
      save.seal.should be_nil

      save[saved].should_not be_nil
      File.read(File.join(location, "seed.txt")).should eq("seed\n")

      list = Git::Stream.new(repo)
      slot = list.stash_list
      list.run.error.should be_nil
      list.seal

      entries = list[slot].as(Array(Git::StashEntry))
      entries.size.should eq(1)
      entries.first.message.should contain("work in progress")
    end
  end

  it "pops a stash back onto the worktree" do
    Fixture.with_repo("cmd_stash_pop") do |repo, location|
      Fixture.seed(repo, location)
      Fixture.write(location, "seed.txt", "changed\n")

      stage = Git::Stream.new(repo)
      stage.stage("seed.txt")
      stage.run.error.should be_nil
      stage.seal

      save = Git::Stream.new(repo, allow_irreversible: true)
      save.stash
      save.run.error.should be_nil
      save.seal

      stream = Git::Stream.new(repo, allow_irreversible: true)
      slot   = stream.stash_pop
      stream.run.error.should be_nil
      stream.seal

      stream[slot].should eq(0)
      File.read(File.join(location, "seed.txt")).should eq("changed\n")
    end
  end

  it "requires acknowledgement for irreversible stash commands" do
    Fixture.with_repo("cmd_stash_guard") do |repo, location|
      Fixture.seed(repo, location)

      stream = Git::Stream.new(repo)
      stream.stash_drop(0)

      result = stream.validate
      result.should be_a(Git::Err)
      result.as(Git::Err).message.should contain("allow_irreversible")
    end
  end
end

describe "query commands" do
  after_each { Fixture.cleanup }

  it "reports untracked and staged entries" do
    Fixture.with_repo("cmd_status") do |repo, location|
      Fixture.seed(repo, location)
      Fixture.write(location, "tracked.txt", "tracked\n")
      Fixture.write(location, "loose.txt", "loose\n")

      stage = Git::Stream.new(repo)
      stage.stage("tracked.txt")
      stage.run.error.should be_nil
      stage.seal

      stream = Git::Stream.new(repo)
      slot   = stream.status(:include_untracked)
      stream.run.error.should be_nil
      stream.seal

      entries = stream[slot].as(Array(Git::StatusEntry))
      paths   = entries.map(&.path)
      paths.should contain("tracked.txt")
      paths.should contain("loose.txt")

      staged = entries.find { |entry| entry.path == "tracked.txt" }
      staged.should_not be_nil
      staged.as(Git::StatusEntry).status.index_new?.should be_true
    end
  end

  it "omits untracked entries without the flag" do
    Fixture.with_repo("cmd_status_flags") do |repo, location|
      Fixture.seed(repo, location)
      Fixture.write(location, "loose.txt", "loose\n")

      stream = Git::Stream.new(repo)
      slot   = stream.status
      stream.run.error.should be_nil
      stream.seal

      entries = stream[slot].as(Array(Git::StatusEntry))
      entries.map(&.path).should_not contain("loose.txt")
    end
  end

  it "lists local branches" do
    Fixture.with_repo("cmd_list_branches") do |repo, location|
      base = Fixture.seed(repo, location)

      create = Git::Stream.new(repo)
      create.create_branch("topic", base.hex)
      create.run.error.should be_nil
      create.seal

      names = Fixture.branch_names(repo)
      names.should contain(Fixture::BRANCH)
      names.should contain("topic")
    end
  end
end
