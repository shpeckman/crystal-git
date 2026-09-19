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

    def initialize(@name : Symbol, @legal_in : StateSet, @leaves : State?,
                   @requires : Predicate, @forbids : Predicate,
                   @sets : Predicate, @clears : Predicate,
                   @reversibility : Reversibility)
    end
  end

  abstract class Command
    abstract def descriptor : Descriptor
    abstract def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err

    macro describe(name, legal_in, leaves, requires, forbids, sets, clears, reversibility)
      DESCRIPTOR = ::Git::Descriptor.new(
        {{name}},
        {{legal_in}},
        {{leaves}},
        {{requires}},
        {{forbids}},
        {{sets}},
        {{clears}},
        {{reversibility}},
      )

      def descriptor : ::Git::Descriptor
        DESCRIPTOR
      end
    end
  end
end
