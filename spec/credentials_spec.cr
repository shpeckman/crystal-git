# spec/credentials_spec.cr
require "./spec_helper"

private def invoke(session : Git::Credentials::Session, url : String,
                   username : String?, allowed : UInt32) : {LibC::Int, LibGit2::Credential}
  cred  = Pointer(Void).null.as(LibGit2::Credential)
  boxed = Box.box(session)
  result = Git::Credentials.callback.call(
    pointerof(cred),
    url.to_unsafe,
    username ? username.to_unsafe : Pointer(LibC::Char).null,
    allowed,
    boxed)
  {result, cred}
end

describe Git::Credentials do
  it "answers a username request before asking for a secret" do
    session = Git::Credentials::Session.new(Git::Credentials::UserPass.new("alice", "hunter2"))

    result, cred = invoke(session, "ssh://example.com/repo.git", nil, Git::Credentials::TYPE_USERNAME)

    result.should eq(0)
    cred.null?.should be_false
    String.new(LibGit2.credential_get_username(cred)).should eq("alice")
    session.attempts.should eq(0)

    LibGit2.credential_free(cred)
  end

  it "falls back to the username in the url" do
    session = Git::Credentials::Session.new(Git::Credentials::Default.new)

    result, cred = invoke(session, "ssh://example.com/repo.git", "bob", Git::Credentials::TYPE_USERNAME)

    result.should eq(0)
    String.new(LibGit2.credential_get_username(cred)).should eq("bob")

    LibGit2.credential_free(cred)
  end

  it "provides plaintext credentials and counts the attempt" do
    session = Git::Credentials::Session.new(Git::Credentials::UserPass.new("alice", "hunter2"))

    result, cred = invoke(session, "https://example.com/repo.git", nil, Git::Credentials::TYPE_USERPASS)

    result.should eq(0)
    cred.null?.should be_false
    LibGit2.credential_has_username(cred).should eq(1)
    String.new(LibGit2.credential_get_username(cred)).should eq("alice")
    session.attempts.should eq(1)

    LibGit2.credential_free(cred)
  end

  it "passes through when the requested type is not supported" do
    session = Git::Credentials::Session.new(Git::Credentials::UserPass.new("alice", "hunter2"))

    result, _ = invoke(session, "https://example.com/repo.git", nil, Git::Credentials::TYPE_SSH_KEY)

    result.should eq(LibGit2::ErrorCode::PASSTHROUGH.value)
  end

  it "gives up after the attempt limit" do
    session = Git::Credentials::Session.new(Git::Credentials::UserPass.new("alice", "hunter2"))
    session.attempts = Git::Credentials::MAX_ATTEMPTS

    result, _ = invoke(session, "https://example.com/repo.git", nil, Git::Credentials::TYPE_USERPASS)

    result.should eq(LibGit2::ErrorCode::EAUTH.value)
  end
end

describe "remote commands" do
  after_each { Fixture.cleanup }

  it "fetches from a local remote with credentials wired in" do
    Fixture.with_repo("cred_source") do |source, source_location|
      head = Fixture.seed(source, source_location)

      Fixture.with_repo("cred_target") do |target, _|
        remote = uninitialized LibGit2::Remote
        url = File.expand_path(source_location)
        LibGit2.remote_create(pointerof(remote), target.handle, "origin", url).should eq(0)
        LibGit2.remote_free(remote)

        target.credentials = Git::Credentials::Default.new

        stream = Git::Stream.new(target, allow_irreversible: true)
        slot   = stream.fetch("origin")
        stream.run.error.should be_nil
        stream.seal

        stream[slot].should eq("origin")

        ref = uninitialized LibGit2::Reference
        LibGit2.reference_lookup(pointerof(ref), target.handle, "refs/remotes/origin/#{Fixture::BRANCH}").should eq(0)
        Git::Oid.from(LibGit2.reference_target(ref)).should eq(head)
        LibGit2.reference_free(ref)
      end
    end
  end

  it "requires acknowledgement for network commands" do
    Fixture.with_repo("cred_guard") do |repo, location|
      Fixture.seed(repo, location)

      stream = Git::Stream.new(repo)
      stream.fetch("origin")

      result = stream.validate
      result.should be_a(Git::Err)
      result.as(Git::Err).message.should contain("allow_irreversible")
    end
  end
end
