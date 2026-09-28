# spec/submodule_spec.cr
require "./spec_helper"

describe "submodules" do
  after_each { Fixture.cleanup }

  it "adds a submodule and lists it" do
    Fixture.with_repo("sub_source") do |source, relative_source|
      source_location = File.expand_path(relative_source)
      head            = Fixture.seed(source, source_location)

      Fixture.with_repo("sub_main") do |repo, location|
        stream = Git::Stream.new(repo)
        name   = stream.submodule_add(source_location, "libs/sub")
        list   = stream.submodule_list
        stream.run.error.should be_nil
        stream.seal

        stream[name].should eq("libs/sub")
        File.exists?(File.join(location, "libs/sub", "seed.txt")).should be_true
        File.exists?(File.join(location, ".gitmodules")).should be_true

        entries = stream[list].as(Array(Git::SubmoduleEntry))
        entries.size.should eq(1)
        entries[0].path.should eq("libs/sub")
        entries[0].url.should eq(source_location)
        entries[0].initialized?.should be_true
        entries[0].workdir_oid.should eq(head)
        entries[0].workdir_oid.should eq(entries[0].index_oid)
        entries[0].modified?.should be_false
        entries[0].added?.should be_true
      end
    end
  end

  it "stages the gitlink and .gitmodules" do
    Fixture.with_repo("sub_stage_source") do |source, relative_source|
      source_location = File.expand_path(relative_source)
      Fixture.seed(source, source_location)

      Fixture.with_repo("sub_stage_main") do |repo, location|
        stream = Git::Stream.new(repo)
        stream.submodule_add(source_location, "libs/sub")
        stream.run.error.should be_nil
        stream.seal

        repo.conditions.as(Git::Ok(Git::Conditions)).value.predicates.dirty_index?.should be_true

        status = Git::Stream.new(repo)
        slot   = status.status
        status.run.error.should be_nil
        status.seal

        paths = status[slot].as(Array(Git::StatusEntry)).map(&.path)
        paths.should contain(".gitmodules")
        paths.should contain("libs/sub")
      end
    end
  end

  it "reports status for a single submodule" do
    Fixture.with_repo("sub_status_source") do |source, relative_source|
      source_location = File.expand_path(relative_source)
      Fixture.seed(source, source_location)

      Fixture.with_repo("sub_status_main") do |repo, location|
        setup = Git::Stream.new(repo)
        setup.submodule_add(source_location, "libs/sub")
        setup.run.error.should be_nil
        setup.seal

        stream = Git::Stream.new(repo)
        slot   = stream.submodule_status("libs/sub")
        stream.run.error.should be_nil
        stream.seal

        entry = stream[slot].as(Git::SubmoduleEntry)
        entry.name.should eq("libs/sub")
        entry.in_config?.should be_true
        entry.in_index?.should be_true
        entry.initialized?.should be_true
      end
    end
  end

  it "reinitializes and updates an uninitialized submodule" do
    Fixture.with_repo("sub_update_source") do |source, relative_source|
      source_location = File.expand_path(relative_source)
      Fixture.seed(source, source_location)

      Fixture.with_repo("sub_update_main") do |repo, location|
        setup = Git::Stream.new(repo)
        setup.submodule_add(source_location, "libs/sub")
        setup.run.error.should be_nil
        setup.seal

        wipe = Git::Stream.new(repo)
        wipe.config_unset("submodule.libs/sub.url")
        wipe.run.error.should be_nil
        wipe.seal

        FileUtils.rm_rf(File.join(location, "libs/sub"))
        FileUtils.rm_rf(File.join(location, ".git", "modules"))

        stream = Git::Stream.new(repo)
        stream.submodule_init("libs/sub")
        stream.submodule_update("libs/sub")
        stream.run.error.should be_nil
        stream.seal

        File.exists?(File.join(location, "libs/sub", "seed.txt")).should be_true
      end
    end
  end

  it "rolls back an added submodule" do
    Fixture.with_repo("sub_rollback_source") do |source, relative_source|
      source_location = File.expand_path(relative_source)
      Fixture.seed(source, source_location)

      Fixture.with_repo("sub_rollback_main") do |repo, location|
        stream = Git::Stream.new(repo)
        stream.submodule_add(source_location, "libs/sub")
        stream.run.error.should be_nil

        File.exists?(File.join(location, "libs/sub")).should be_true

        stream.rollback.should be_nil
        stream.seal

        File.exists?(File.join(location, "libs/sub")).should be_false

        check = Git::Stream.new(repo)
        list  = check.submodule_list
        url   = check.config_get("submodule.libs/sub.url")
        check.run.error.should be_nil
        check.seal

        check[list].as(Array(Git::SubmoduleEntry)).should be_empty
        check[url].should be_nil
      end
    end
  end

  it "syncs the configured url into the submodule repository" do
    Fixture.with_repo("sub_sync_source") do |source, relative_source|
      source_location = File.expand_path(relative_source)
      Fixture.seed(source, source_location)

      Fixture.with_repo("sub_sync_main") do |repo, location|
        setup = Git::Stream.new(repo)
        setup.submodule_add(source_location, "libs/sub")
        setup.run.error.should be_nil
        setup.seal

        stream = Git::Stream.new(repo)
        stream.config_set("submodule.libs/sub.url", "https://example.com/moved.git")
        synced = stream.submodule_sync
        stream.run.error.should be_nil
        stream.seal

        stream[synced].should eq(1)

        child_result = Git::Repo.open(File.join(location, "libs/sub"))
        child_result.should be_a(Git::Ok(Git::Repo))
        child = child_result.as(Git::Ok(Git::Repo)).value
        begin
          check = Git::Stream.new(child)
          url   = check.config_get("remote.origin.url")
          check.run.error.should be_nil
          check.seal
          check[url].should eq("https://example.com/moved.git")
        ensure
          child.close
        end
      end
    end
  end

  it "is refused while the repository is mid-merge" do
    Fixture.with_repo("sub_conflict_source") do |source, relative_source|
      source_location = File.expand_path(relative_source)
      Fixture.seed(source, source_location)

      Fixture.with_repo("sub_conflict_main") do |repo, location|
        base = Fixture.seed(repo, location)

        branch = Git::Stream.new(repo)
        branch.create_branch("topic", base.hex)
        branch.run.error.should be_nil
        branch.seal

        Fixture.commit(repo, location, "seed.txt", "master\n", "master work")

        switch = Git::Stream.new(repo)
        switch.checkout("topic")
        switch.run.error.should be_nil
        switch.seal

        Fixture.commit(repo, location, "seed.txt", "topic\n", "topic work")

        back = Git::Stream.new(repo)
        back.checkout("master")
        back.run.error.should be_nil
        back.seal

        merge = Git::Stream.new(repo)
        merge.merge("topic")
        merge.run.error.should be_nil
        merge.seal

        Fixture.state(repo).should eq(Git::State::Merge)

        stream = Git::Stream.new(repo)
        stream.submodule_add(source_location, "libs/sub")
        stream.run.error.should be_a(Git::Err)
      end
    end
  end
end
