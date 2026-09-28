# spec/inspect_spec.cr
require "./spec_helper"

describe "object inspection" do
  after_each { Fixture.cleanup }

  it "reads a blob by rev:path" do
    Fixture.with_repo("inspect_blob") do |repo, location|
      Fixture.seed(repo, location)

      stream = Git::Stream.new(repo)
      slot   = stream.read_blob("HEAD:seed.txt")
      stream.run.error.should be_nil
      stream.seal

      String.new(stream[slot].as(Bytes)).should eq("seed\n")
    end
  end

  it "fails to read a missing blob" do
    Fixture.with_repo("inspect_blob_missing") do |repo, location|
      Fixture.seed(repo, location)

      stream = Git::Stream.new(repo)
      stream.read_blob("HEAD:missing.txt")
      stream.run.error.should be_a(Git::Err)
    end
  end

  it "fails when the spec is not a blob" do
    Fixture.with_repo("inspect_blob_tree") do |repo, location|
      Fixture.seed(repo, location)

      stream = Git::Stream.new(repo)
      stream.read_blob("HEAD^{tree}")
      stream.run.error.should be_a(Git::Err)
    end
  end

  it "reads a raw commit object" do
    Fixture.with_repo("inspect_object") do |repo, location|
      head = Fixture.seed(repo, location, "inspected")

      stream = Git::Stream.new(repo)
      slot   = stream.read_object(head.hex)
      stream.run.error.should be_nil
      stream.seal

      data = stream[slot].as(Git::ObjectData)
      data.kind.should eq(Git::ObjectKind::Commit)
      data.text.should contain("inspected")
    end
  end

  it "lists a tree shallowly" do
    Fixture.with_repo("inspect_tree") do |repo, location|
      Fixture.seed(repo, location)
      Fixture.commit(repo, location, "dir/nested.txt", "nested\n", "nested")

      stream = Git::Stream.new(repo)
      slot   = stream.tree_list
      stream.run.error.should be_nil
      stream.seal

      entries = stream[slot].as(Array(Git::TreeEntryInfo))
      entries.map(&.name).sort.should eq(["dir", "seed.txt"])
      entries.find(&.tree?).not_nil!.name.should eq("dir")
      entries.find(&.blob?).not_nil!.name.should eq("seed.txt")
    end
  end

  it "lists a tree recursively" do
    Fixture.with_repo("inspect_tree_recursive") do |repo, location|
      Fixture.seed(repo, location)
      Fixture.commit(repo, location, "dir/nested.txt", "nested\n", "nested")

      stream = Git::Stream.new(repo)
      slot   = stream.tree_list(recursive: true)
      stream.run.error.should be_nil
      stream.seal

      entries = stream[slot].as(Array(Git::TreeEntryInfo))
      entries.map(&.path).should contain("dir/nested.txt")
      entries.map(&.path).should contain("dir")
      entries.map(&.path).should contain("seed.txt")
    end
  end

  it "lists a subtree by path" do
    Fixture.with_repo("inspect_tree_path") do |repo, location|
      Fixture.seed(repo, location)
      Fixture.commit(repo, location, "dir/nested.txt", "nested\n", "nested")

      stream = Git::Stream.new(repo)
      slot   = stream.tree_list(path: "dir")
      stream.run.error.should be_nil
      stream.seal

      entries = stream[slot].as(Array(Git::TreeEntryInfo))
      entries.size.should eq(1)
      entries[0].name.should eq("nested.txt")
      entries[0].oid.should_not eq(Git::Oid.zero)
    end
  end

  it "refuses to list a blob as a tree" do
    Fixture.with_repo("inspect_tree_blob") do |repo, location|
      Fixture.seed(repo, location)

      stream = Git::Stream.new(repo)
      stream.tree_list(path: "seed.txt")
      stream.run.error.should be_a(Git::Err)
    end
  end

  it "hashes data without writing it" do
    Fixture.with_repo("inspect_hash") do |repo, location|
      Fixture.seed(repo, location)

      stream = Git::Stream.new(repo)
      slot   = stream.hash_object("hello\n")
      stream.run.error.should be_nil
      stream.seal

      stream[slot].as(Git::Oid).hex.should eq("ce013625030ba8dba906f756967f9e9ca394464a")

      read = Git::Stream.new(repo)
      blob = read.read_blob("ce013625030ba8dba906f756967f9e9ca394464a")
      read.run.error.should be_a(Git::Err)
    end
  end

  it "writes a blob that can be read back" do
    Fixture.with_repo("inspect_write_blob") do |repo, location|
      Fixture.seed(repo, location)

      stream = Git::Stream.new(repo)
      slot   = stream.hash_object("stored content\n", write: true)
      stream.run.error.should be_nil
      stream.seal

      oid = stream[slot].as(Git::Oid)

      read = Git::Stream.new(repo)
      blob = read.read_blob(oid.hex)
      read.run.error.should be_nil
      read.seal

      String.new(read[blob].as(Bytes)).should eq("stored content\n")
    end
  end
end
