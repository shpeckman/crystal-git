# src/git/command.cr
module Git
  struct Descriptor
    getter name          : Symbol
    getter legal_in      : StateSet
    getter leaves        : State?
    getter requires      : Predicate
    getter forbids       : Predicate
    getter sets          : Predicate
    getter clears        : Predicate
    getter reversibility : Reversibility
    getter requires_in   : StateSet

    def initialize(@name : Symbol, @legal_in : StateSet, @leaves : State?,
                   @requires : Predicate, @forbids : Predicate,
                   @sets : Predicate, @clears : Predicate,
                   @reversibility : Reversibility,
                   @requires_in   : StateSet = StateSet::All)
    end
  end

  abstract class Command
    abstract def descriptor : Descriptor
    abstract def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err

    macro describe(name, legal_in, leaves, requires, forbids, sets, clears, reversibility, requires_in = ::Git::StateSet::All)
      DESCRIPTOR = ::Git::Descriptor.new(
        {{name}},
        {{legal_in}},
        {{leaves}},
        {{requires}},
        {{forbids}},
        {{sets}},
        {{clears}},
        {{reversibility}},
        {{requires_in}},
      )

      def descriptor : ::Git::Descriptor
        DESCRIPTOR
      end
    end
  end
end
