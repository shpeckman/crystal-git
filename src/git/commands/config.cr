# src/git/commands/config.cr
module Git::Commands
  class ConfigGet < Command
    describe(:config_get, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::ReadOnly)

    def initialize(@name : String)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      read = repo.with_config do |_, config|
        value = uninitialized LibC::Char*
        result = LibGit2.config_get_string(pointerof(value), config, @name)
        if result == LibGit2::ErrorCode::ENOTFOUND.value
          nil
        elsif err = Git.check(result)
          return err
        else
          String.new(value)
        end
      end
      return read if read.is_a?(Err)
      Ok(Value).new(read.value)
    end
  end

  class ConfigSet < Command
    describe(:config_set, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::RefOnly)

    def initialize(@name : String, @value : String)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      record = Undo::ConfigEntry.capture(repo, @name)
      return record if record.is_a?(Err)

      written = repo.with_config do |config, _|
        if err = Git.check(LibGit2.config_set_string(config, @name, @value))
          return err
        end
        @value
      end
      return written if written.is_a?(Err)

      undo << record.value
      Ok(Value).new(@value)
    end
  end

  class ConfigUnset < Command
    describe(:config_unset, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::RefOnly)

    def initialize(@name : String)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      record = Undo::ConfigEntry.capture(repo, @name)
      return record if record.is_a?(Err)

      deleted = repo.with_config do |config, _|
        if err = Git.check(LibGit2.config_delete_entry(config, @name))
          return err
        end
        nil
      end
      return deleted if deleted.is_a?(Err)

      undo << record.value
      Ok(Value).new(@name)
    end
  end

  class ConfigList < Command
    describe(:config_list, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::ReadOnly)

    def initialize(@glob : String?)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      listed = repo.with_config do |_, config|
        iterator = uninitialized LibGit2::ConfigIterator
        result = if glob = @glob
                   LibGit2.config_iterator_glob_new(pointerof(iterator), config, glob)
                 else
                   LibGit2.config_iterator_new(pointerof(iterator), config)
                 end
        if err = Git.check(result)
          return err
        end

        items = [] of ConfigItem
        loop do
          entry = uninitialized LibGit2::ConfigEntry*
          res = LibGit2.config_next(pointerof(entry), iterator)
          break if res == LibGit2::ErrorCode::ITEROVER.value

          if res != 0
            failure = Err.capture(res)
            LibGit2.config_iterator_free(iterator)
            return failure
          end

          record = entry.value
          next if record.name.null? || record.value.null?
          items << ConfigItem.new(String.new(record.name), String.new(record.value))
        end

        LibGit2.config_iterator_free(iterator)
        items
      end
      return listed if listed.is_a?(Err)
      Ok(Value).new(listed.value)
    end
  end
end
