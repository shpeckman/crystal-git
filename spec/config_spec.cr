# spec/config_spec.cr
require "./spec_helper"

describe "config" do
  after_each { Fixture.cleanup }

  it "returns nil for a missing key" do
    Fixture.with_repo("config_missing") do |repo, _|
      stream = Git::Stream.new(repo)
      slot   = stream.config_get("spec.missing")
      stream.run.error.should be_nil
      stream.seal

      stream[slot].should be_nil
    end
  end

  it "sets and reads back a value" do
    Fixture.with_repo("config_roundtrip") do |repo, _|
      stream = Git::Stream.new(repo)
      stream.config_set("spec.key", "hello")
      slot = stream.config_get("spec.key")
      stream.run.error.should be_nil
      stream.seal

      stream[slot].should eq("hello")
    end
  end

  it "unsets a value" do
    Fixture.with_repo("config_unset") do |repo, _|
      setup = Git::Stream.new(repo)
      setup.config_set("spec.key", "hello")
      setup.run.error.should be_nil
      setup.seal

      stream = Git::Stream.new(repo)
      stream.config_unset("spec.key")
      slot = stream.config_get("spec.key")
      stream.run.error.should be_nil
      stream.seal

      stream[slot].should be_nil
    end
  end

  it "lists entries with a glob" do
    Fixture.with_repo("config_list") do |repo, _|
      setup = Git::Stream.new(repo)
      setup.config_set("spec.one", "1")
      setup.config_set("spec.two", "2")
      setup.run.error.should be_nil
      setup.seal

      stream = Git::Stream.new(repo)
      slot   = stream.config_list("spec\\..*")
      stream.run.error.should be_nil
      stream.seal

      items = stream[slot].as(Array(Git::ConfigItem))
      items.should contain(Git::ConfigItem.new("spec.one", "1"))
      items.should contain(Git::ConfigItem.new("spec.two", "2"))
    end
  end

  it "rolls back a set to the previous value" do
    Fixture.with_repo("config_rollback_set") do |repo, _|
      setup = Git::Stream.new(repo)
      setup.config_set("spec.key", "before")
      setup.run.error.should be_nil
      setup.seal

      stream = Git::Stream.new(repo)
      stream.config_set("spec.key", "after")
      stream.run.error.should be_nil
      stream.rollback.should be_nil
      stream.seal

      check = Git::Stream.new(repo)
      slot  = check.config_get("spec.key")
      check.run.error.should be_nil
      check.seal

      check[slot].should eq("before")
    end
  end

  it "rolls back a set of a previously absent key" do
    Fixture.with_repo("config_rollback_absent") do |repo, _|
      stream = Git::Stream.new(repo)
      stream.config_set("spec.fresh", "value")
      stream.run.error.should be_nil
      stream.rollback.should be_nil
      stream.seal

      check = Git::Stream.new(repo)
      slot  = check.config_get("spec.fresh")
      check.run.error.should be_nil
      check.seal

      check[slot].should be_nil
    end
  end

  it "rolls back an unset" do
    Fixture.with_repo("config_rollback_unset") do |repo, _|
      setup = Git::Stream.new(repo)
      setup.config_set("spec.key", "kept")
      setup.run.error.should be_nil
      setup.seal

      stream = Git::Stream.new(repo)
      stream.config_unset("spec.key")
      stream.run.error.should be_nil
      stream.rollback.should be_nil
      stream.seal

      check = Git::Stream.new(repo)
      slot  = check.config_get("spec.key")
      check.run.error.should be_nil
      check.seal

      check[slot].should eq("kept")
    end
  end
end
