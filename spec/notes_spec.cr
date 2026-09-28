# spec/notes_spec.cr
require "./spec_helper"

describe "notes" do
  after_each { Fixture.cleanup }

  it "adds, shows, and lists a note" do
    Fixture.with_repo("notes_basic") do |repo, location|
      head = Fixture.seed(repo, location)

      stream = Git::Stream.new(repo)
      added  = stream.note_add("HEAD", "looks good")
      shown  = stream.note_show("HEAD")
      listed = stream.note_list
      stream.run.error.should be_nil
      stream.seal

      blob = stream[added].as(Git::Oid)

      note = stream[shown].as(Git::Note)
      note.object.should eq(head)
      note.blob.should eq(blob)
      note.message.should eq("looks good")
      note.author.should eq("Spec Runner")

      entries = stream[listed].as(Array(Git::NoteEntry))
      entries.size.should eq(1)
      entries[0].object.should eq(head)
      entries[0].blob.should eq(blob)
    end
  end

  it "returns nil when showing a missing note and an empty list" do
    Fixture.with_repo("notes_missing") do |repo, location|
      Fixture.seed(repo, location)

      stream = Git::Stream.new(repo)
      shown  = stream.note_show("HEAD")
      listed = stream.note_list
      stream.run.error.should be_nil
      stream.seal

      stream[shown].should be_nil
      stream[listed].as(Array(Git::NoteEntry)).should be_empty
    end
  end

  it "refuses to overwrite without force and overwrites with force" do
    Fixture.with_repo("notes_force") do |repo, location|
      Fixture.seed(repo, location)

      first = Git::Stream.new(repo)
      first.note_add("HEAD", "first")
      first.run.error.should be_nil
      first.seal

      second = Git::Stream.new(repo)
      second.note_add("HEAD", "second")
      second.run.error.should be_a(Git::Err)

      third = Git::Stream.new(repo)
      third.note_add("HEAD", "second", force: true)
      shown = third.note_show("HEAD")
      third.run.error.should be_nil
      third.seal

      third[shown].as(Git::Note).message.should eq("second")
    end
  end

  it "removes a note" do
    Fixture.with_repo("notes_remove") do |repo, location|
      Fixture.seed(repo, location)

      setup = Git::Stream.new(repo)
      setup.note_add("HEAD", "temporary")
      setup.run.error.should be_nil
      setup.seal

      stream = Git::Stream.new(repo)
      stream.note_remove("HEAD")
      shown = stream.note_show("HEAD")
      stream.run.error.should be_nil
      stream.seal

      stream[shown].should be_nil
    end
  end

  it "restores an overwritten note on rollback" do
    Fixture.with_repo("notes_rollback") do |repo, location|
      Fixture.seed(repo, location)

      setup = Git::Stream.new(repo)
      setup.note_add("HEAD", "original")
      setup.run.error.should be_nil
      setup.seal

      overwrite = Git::Stream.new(repo)
      overwrite.note_add("HEAD", "replacement", force: true)
      overwrite.run.error.should be_nil
      overwrite.rollback.should be_nil
      overwrite.seal

      check = Git::Stream.new(repo)
      shown = check.note_show("HEAD")
      check.run.error.should be_nil
      check.seal
      check[shown].as(Git::Note).message.should eq("original")
    end
  end

  it "drops an added note on rollback" do
    Fixture.with_repo("notes_add_rollback") do |repo, location|
      Fixture.seed(repo, location)

      stream = Git::Stream.new(repo)
      stream.note_add("HEAD", "temporary")
      stream.run.error.should be_nil
      stream.rollback.should be_nil
      stream.seal

      check = Git::Stream.new(repo)
      shown = check.note_show("HEAD")
      check.run.error.should be_nil
      check.seal
      check[shown].should be_nil
    end
  end

  it "restores a removed note on rollback" do
    Fixture.with_repo("notes_remove_rollback") do |repo, location|
      Fixture.seed(repo, location)

      setup = Git::Stream.new(repo)
      setup.note_add("HEAD", "keep me")
      setup.run.error.should be_nil
      setup.seal

      stream = Git::Stream.new(repo)
      stream.note_remove("HEAD")
      stream.run.error.should be_nil
      stream.rollback.should be_nil
      stream.seal

      check = Git::Stream.new(repo)
      shown = check.note_show("HEAD")
      check.run.error.should be_nil
      check.seal
      check[shown].as(Git::Note).message.should eq("keep me")
    end
  end

  it "uses a custom notes ref" do
    Fixture.with_repo("notes_ref") do |repo, location|
      Fixture.seed(repo, location)

      stream = Git::Stream.new(repo)
      stream.note_add("HEAD", "review note", ref: "refs/notes/review")
      default = stream.note_show("HEAD")
      custom  = stream.note_show("HEAD", ref: "refs/notes/review")
      listed  = stream.note_list("refs/notes/review")
      stream.run.error.should be_nil
      stream.seal

      stream[default].should be_nil
      stream[custom].as(Git::Note).message.should eq("review note")
      stream[listed].as(Array(Git::NoteEntry)).size.should eq(1)
    end
  end
end
