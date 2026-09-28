# src/git/commands/describe.cr
module Git::Commands
  class Describe < Command
    describe(:describe, StateSet::All, nil,
      Predicate::None, Predicate::None,
      Predicate::None, Predicate::None,
      Reversibility::ReadOnly)

    def initialize(@target : String?, @all : Bool, @tags : Bool, @first_parent : Bool,
                   @long : Bool, @always : Bool, @dirty : Bool, @abbrev : Int32?)
    end

    def execute(repo : Repo, undo : Array(Undo)) : Ok(Value) | Err
      if @dirty && @target
        return Err.invalid("describe with dirty applies to the workdir, not a target")
      end

      opts = uninitialized LibGit2::DescribeOptions
      if err = Git.check(LibGit2.describe_options_init(pointerof(opts), 1_u32))
        return err
      end
      opts.describe_strategy = strategy.value.to_u32
      opts.only_follow_first_parent = @first_parent ? 1 : 0
      opts.show_commit_oid_as_fallback = @always ? 1 : 0

      result = uninitialized LibGit2::DescribeResult
      if target = @target
        object = uninitialized LibGit2::Object
        if err = Git.check(LibGit2.revparse_single(pointerof(object), repo.handle, target))
          return err
        end
        rc = LibGit2.describe_commit(pointerof(result), object, pointerof(opts))
        LibGit2.object_free(object)
        if err = Git.check(rc)
          return err
        end
      else
        if err = Git.check(LibGit2.describe_workdir(pointerof(result), repo.handle, pointerof(opts)))
          return err
        end
      end

      format = uninitialized LibGit2::DescribeFormatOptions
      if err = Git.check(LibGit2.describe_format_options_init(pointerof(format), 1_u32))
        LibGit2.describe_result_free(result)
        return err
      end
      format.always_use_long_format = @long ? 1 : 0
      format.dirty_suffix = "-dirty".to_unsafe if @dirty
      if abbrev = @abbrev
        format.abbreviated_size = abbrev.to_u32
      end

      buffer = LibGit2::Buf.new
      rc     = LibGit2.describe_format(pointerof(buffer), result, pointerof(format))
      LibGit2.describe_result_free(result)
      if err = Git.check(rc)
        return err
      end

      text = buffer.size == 0 ? "" : String.new(buffer.ptr, buffer.size)
      LibGit2.buf_dispose(pointerof(buffer))
      Ok(Value).new(text)
    end

    private def strategy : LibGit2::DescribeStrategy
      return LibGit2::DescribeStrategy::ALL if @all
      return LibGit2::DescribeStrategy::TAGS if @tags
      LibGit2::DescribeStrategy::DEFAULT
    end
  end
end
