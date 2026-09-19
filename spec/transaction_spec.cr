# spec/transaction_spec.cr
require "./spec_helper"

describe Git::RefIntent do
  it "treats a missing target as a removal" do
    Git::RefIntent.new("refs/heads/gone").removal?.should be_true
  end

  it "is not a removal when a target is present" do
    oid = Git::Oid.parse("0" * 40).as(Git::Ok(Git::Oid)).value
    Git::RefIntent.new("refs/heads/kept", oid).removal?.should be_false
  end
end

describe Git::RefTransaction do
  after_each { Fixture.cleanup }

  it "applies several ref updates in one transaction" do
    Fixture.with_repo("tx_apply") do |repo, location|
      base = Fixture.seed(repo, location)

      intents = [
        Git::RefIntent.new("refs/heads/one", base),
        Git::RefIntent.new("refs/heads/two", base),
        Git::RefIntent.new("refs/heads/three", base),
      ]

      Git::RefTransaction.apply(repo, intents).should be_nil

      names = Fixture.branch_names(repo)
      names.should contain("one")
      names.should contain("two")
      names.should contain("three")
    end
  end

  it "removes refs through a transaction" do
    Fixture.with_repo("tx_remove") do |repo, location|
      base = Fixture.seed(repo, location)

      Git::RefTransaction.apply(repo, [Git::RefIntent.new("refs/heads/temp", base)]).should be_nil
      Fixture.branch_names(repo).should contain("temp")

      Git::RefTransaction.apply(repo, [Git::RefIntent.new("refs/heads/temp")]).should be_nil
      Fixture.branch_names(repo).should_not contain("temp")
    end
  end

  it "tolerates removing a ref that does not exist" do
    Fixture.with_repo("tx_missing") do |repo, location|
      Fixture.seed(repo, location)

      Git::RefTransaction.apply(repo, [Git::RefIntent.new("refs/heads/never")]).should be_nil
    end
  end

  it "keeps the last intent when a ref appears twice" do
    Fixture.with_repo("tx_dedupe") do |repo, location|
      base   = Fixture.seed(repo, location)
      second = Fixture.commit(repo, location, "b.txt", "b\n", "second")

      intents = [
        Git::RefIntent.new("refs/heads/dup", second),
        Git::RefIntent.new("refs/heads/dup", base),
      ]

      Git::RefTransaction.apply(repo, intents).should be_nil

      ref = uninitialized LibGit2::Reference
      LibGit2.branch_lookup(pointerof(ref), repo.handle, "dup", LibGit2::BranchType::LOCAL).should eq(0)
      Git::Oid.from(LibGit2.reference_target(ref)).should eq(base)
      LibGit2.reference_free(ref)
    end
  end

  it "rolls back several branches atomically" do
    Fixture.with_repo("tx_rollback") do |repo, location|
      base = Fixture.seed(repo, location)

      stream = Git::Stream.new(repo)
      stream.create_branch("one", base.hex)
      stream.create_branch("two", base.hex)
      stream.create_branch("three", base.hex)
      stream.run.error.should be_nil

      names = Fixture.branch_names(repo)
      names.should contain("one")
      names.should contain("three")

      stream.rollback.should be_nil
      stream.seal

      after = Fixture.branch_names(repo)
      after.should_not contain("one")
      after.should_not contain("two")
      after.should_not contain("three")
    end
  end
end
