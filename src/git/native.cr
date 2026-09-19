# src/git/native.cr
require "file_utils"

module Git::Native
  def self.strarray(paths : Array(String), & : LibGit2::Strarray* -> Err?) : Err?
    pointers = paths.map(&.to_unsafe)
    array    = LibGit2::Strarray.new
    array.strings = pointers.to_unsafe
    array.count = paths.size.to_u64
    yield pointerof(array)
  end

  def self.free_object(object : LibGit2::Object) : Nil
    LibGit2.object_free(object)
  end

  def self.checkout_options(strategy : UInt32) : LibGit2::CheckoutOptions
    opts = uninitialized LibGit2::CheckoutOptions
    LibGit2.checkout_options_init(pointerof(opts), 1_u32)
    opts.checkout_strategy = strategy
    opts
  end

  def self.merge_options(flags : UInt32) : LibGit2::MergeOptions
    opts = uninitialized LibGit2::MergeOptions
    LibGit2.merge_options_init(pointerof(opts), 1_u32)
    opts.flags = flags
    opts
  end

  def self.text(pointer : LibC::Char*) : String?
    pointer.null? ? nil : String.new(pointer)
  end

  def self.pointer(text : String?) : LibC::Char*
    text ? text.to_unsafe : Pointer(LibC::Char).null
  end

  def self.read_bytes(path : String) : Bytes
    File.open(path, "rb") { |file| file.getb_to_end }
  end

  def self.write_bytes(path : String, bytes : Bytes) : Nil
    Dir.mkdir_p(File.dirname(path))
    File.open(path, "wb") { |file| file.write(bytes) }
  end

  def self.discard(path : String) : Nil
    if File.directory?(path)
      FileUtils.rm_rf(path)
    elsif File.exists?(path) || File.symlink?(path)
      File.delete(path)
    end
  end

  def self.workdir(repo : Repo) : Ok(String) | Err
    path = text(LibGit2.repository_workdir(repo.handle))
    return Err.invalid("repository has no working directory") unless path
    Ok(String).new(path)
  end

  def self.gitdir(repo : Repo) : Ok(String) | Err
    path = text(LibGit2.repository_path(repo.handle))
    return Err.invalid("repository has no git directory") unless path
    Ok(String).new(path)
  end

  def self.oid(repo : Repo, revspec : String) : Ok(Oid) | Err
    object = uninitialized LibGit2::Object
    if err = Git.check(LibGit2.revparse_single(pointerof(object), repo.handle, revspec))
      return err
    end
    id = Oid.from(LibGit2.object_id(object))
    free_object(object)
    Ok(Oid).new(id)
  end

  def self.commit(repo : Repo, revspec : String) : Ok(LibGit2::Commit) | Err
    object = uninitialized LibGit2::Object
    if err = Git.check(LibGit2.revparse_single(pointerof(object), repo.handle, revspec))
      return err
    end

    peeled = uninitialized LibGit2::Object
    result = Git.check(LibGit2.object_peel(pointerof(peeled), object, LibGit2::ObjectType::COMMIT))
    free_object(object)
    return result if result

    Ok(LibGit2::Commit).new(peeled.as(LibGit2::Commit))
  end

  def self.annotated(repo : Repo, revspec : String) : Ok(LibGit2::AnnotatedCommit) | Err
    annotated = uninitialized LibGit2::AnnotatedCommit
    if err = Git.check(LibGit2.annotated_commit_from_revspec(pointerof(annotated), repo.handle, revspec))
      return err
    end
    Ok(LibGit2::AnnotatedCommit).new(annotated)
  end

  def self.null_annotated : LibGit2::AnnotatedCommit
    Pointer(Void).null.as(LibGit2::AnnotatedCommit)
  end
end
