# spec/state_spec.cr
require "./spec_helper"

describe Git::State do
  it "maps native repository states" do
    Git::State.from_native(0).should eq(Git::State::Clean)
    Git::State.from_native(1).should eq(Git::State::Merge)
    Git::State.from_native(7).should eq(Git::State::Rebase)
  end

  it "falls back to clean for out of range values" do
    Git::State.from_native(-1).should eq(Git::State::Clean)
    Git::State.from_native(99).should eq(Git::State::Clean)
  end

  it "converts to a single member set" do
    Git::State::Merge.to_set.should eq(Git::StateSet::Merge)
    Git::State::Clean.to_set.should eq(Git::StateSet::Clean)
  end
end

describe Git::Conditions do
  it "applies the state left behind by a descriptor" do
    descriptor = Git::Descriptor.new(
      :spec, Git::StateSet::All, Git::State::Merge,
      Git::Predicate::None, Git::Predicate::None,
      Git::Predicate::None, Git::Predicate::None,
      Git::Reversibility::RefOnly)

    conditions = Git::Conditions.new(Git::State::Clean, Git::Predicate::None)

    conditions.advance(descriptor).state.should eq(Git::State::Merge)
  end

  it "keeps the current state when a descriptor leaves none" do
    descriptor = Git::Descriptor.new(
      :spec, Git::StateSet::All, nil,
      Git::Predicate::None, Git::Predicate::None,
      Git::Predicate::None, Git::Predicate::None,
      Git::Reversibility::ReadOnly)

    conditions = Git::Conditions.new(Git::State::Rebase, Git::Predicate::None)

    conditions.advance(descriptor).state.should eq(Git::State::Rebase)
  end

  it "sets and clears predicates" do
    descriptor = Git::Descriptor.new(
      :spec, Git::StateSet::All, nil,
      Git::Predicate::None, Git::Predicate::None,
      Git::Predicate::DirtyIndex, Git::Predicate::Conflicted,
      Git::Reversibility::IndexOnly)

    conditions = Git::Conditions.new(Git::State::Clean, Git::Predicate::Conflicted)
    advanced   = conditions.advance(descriptor)

    advanced.predicates.dirty_index?.should be_true
    advanced.predicates.conflicted?.should be_false
  end
end
