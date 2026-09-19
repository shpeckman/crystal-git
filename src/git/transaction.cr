# src/git/transaction.cr
module Git
  struct RefIntent
    getter name     : String
    getter target   : Oid?
    getter symbolic : String?

    def initialize(@name : String, @target : Oid? = nil, @symbolic : String? = nil)
    end

    def removal? : Bool
      @target.nil? && @symbolic.nil?
    end
  end

  module RefTransaction
    def self.apply(repo : Repo, intents : Array(RefIntent)) : Err?
      batch = dedupe(intents)
      return nil if batch.empty?
      return nil unless atomic(repo, batch)
      sequential(repo, batch)
    end

    def self.write(repo : Repo, intent : RefIntent) : Err?
      ref = uninitialized LibGit2::Reference

      if symbolic = intent.symbolic
        if err = Git.check(LibGit2.reference_symbolic_create(pointerof(ref), repo.handle, intent.name, symbolic, 1, nil))
          return err
        end
        LibGit2.reference_free(ref)
        return nil
      end

      if target = intent.target
        raw = target.raw
        if err = Git.check(LibGit2.reference_create(pointerof(ref), repo.handle, intent.name, pointerof(raw), 1, nil))
          return err
        end
        LibGit2.reference_free(ref)
        return nil
      end

      result = LibGit2.reference_remove(repo.handle, intent.name)
      return nil if result == LibGit2::ErrorCode::ENOTFOUND.value
      Git.check(result)
    end

    private def self.dedupe(intents : Array(RefIntent)) : Array(RefIntent)
      seen = {} of String => RefIntent
      intents.each { |intent| seen[intent.name] = intent }
      seen.values
    end

    private def self.atomic(repo : Repo, batch : Array(RefIntent)) : Err?
      tx = uninitialized LibGit2::Transaction
      if err = Git.check(LibGit2.transaction_new(pointerof(tx), repo.handle))
        return err
      end

      locked = [] of RefIntent
      batch.each do |intent|
        result = LibGit2.transaction_lock_ref(tx, intent.name)
        if result == LibGit2::ErrorCode::ENOTFOUND.value && intent.removal?
          next
        end
        if result != 0
          failure = Err.capture(result)
          LibGit2.transaction_free(tx)
          return failure
        end
        locked << intent
      end

      locked.each do |intent|
        result = if symbolic = intent.symbolic
                   LibGit2.transaction_set_symbolic_target(tx, intent.name, symbolic, nil, nil)
                 elsif target = intent.target
                   raw = target.raw
                   LibGit2.transaction_set_target(tx, intent.name, pointerof(raw), nil, nil)
                 else
                   LibGit2.transaction_remove(tx, intent.name)
                 end

        if result != 0
          failure = Err.capture(result)
          LibGit2.transaction_free(tx)
          return failure
        end
      end

      committed = Git.check(LibGit2.transaction_commit(tx))
      LibGit2.transaction_free(tx)
      committed
    end

    private def self.sequential(repo : Repo, batch : Array(RefIntent)) : Err?
      failure = nil.as(Err?)
      batch.each do |intent|
        if err = write(repo, intent)
          failure ||= err
        end
      end
      failure
    end
  end
end
