# src/git/c/credential.cr
@[Link("git2")]
lib LibGit2
  # ============================================================================
  # CREDENTIALS (git2/credential.h)
  # ============================================================================

  enum CredentialType
    USERPASS_PLAINTEXT =  1
    SSH_KEY            =  2
    SSH_CUSTOM         =  4
    DEFAULT            =  8
    SSH_INTERACTIVE    = 16
    USERNAME           = 32
    SSH_MEMORY         = 64
  end

  alias CredentialAcquireCb = (Credential*, LibC::Char*, LibC::Char*, LibC::UInt, Void* -> LibC::Int)
  alias CredentialSignCb = (Void*, LibC::Char**, LibC::SizeT*, LibC::Char*, LibC::SizeT, Void** -> LibC::Int)

  fun credential_free = git_credential_free(cred : Credential)
  fun credential_has_username = git_credential_has_username(cred : Credential) : LibC::Int
  fun credential_get_username = git_credential_get_username(cred : Credential) : LibC::Char*

  fun credential_userpass_plaintext_new = git_credential_userpass_plaintext_new(out_cred : Credential*, username : LibC::Char*, password : LibC::Char*) : LibC::Int
  fun credential_default_new = git_credential_default_new(out_cred : Credential*) : LibC::Int
  fun credential_username_new = git_credential_username_new(out_cred : Credential*, username : LibC::Char*) : LibC::Int

  fun credential_ssh_key_new = git_credential_ssh_key_new(out_cred : Credential*, username : LibC::Char*, publickey : LibC::Char*, privatekey : LibC::Char*, passphrase : LibC::Char*) : LibC::Int
  fun credential_ssh_key_memory_new = git_credential_ssh_key_memory_new(out_cred : Credential*, username : LibC::Char*, publickey : LibC::Char*, privatekey : LibC::Char*, passphrase : LibC::Char*) : LibC::Int
  fun credential_ssh_key_from_agent = git_credential_ssh_key_from_agent(out_cred : Credential*, username : LibC::Char*) : LibC::Int

  fun credential_ssh_custom_new = git_credential_ssh_custom_new(out_cred : Credential*, username : LibC::Char*, publickey : LibC::Char*, publickey_len : LibC::SizeT, sign_callback : CredentialSignCb, payload : Void*) : LibC::Int
end
