# src/git/credentials.cr
module Git
  abstract class Credentials
    MAX_ATTEMPTS = 3

    TYPE_USERPASS = LibGit2::CredentialType::USERPASS_PLAINTEXT.value.to_u32
    TYPE_SSH_KEY  = LibGit2::CredentialType::SSH_KEY.value.to_u32
    TYPE_DEFAULT  = LibGit2::CredentialType::DEFAULT.value.to_u32
    TYPE_USERNAME = LibGit2::CredentialType::USERNAME.value.to_u32

    PASSTHROUGH = LibGit2::ErrorCode::PASSTHROUGH.value
    EAUTH       = LibGit2::ErrorCode::EAUTH.value

    class Session
      getter credentials : Credentials
      property attempts  : Int32

      def initialize(@credentials : Credentials)
        @attempts = 0
      end
    end

    abstract def provide(out_cred : LibGit2::Credential*, url : String, username : String, allowed : UInt32) : LibC::Int

    def username : String?
      nil
    end

    def self.callback : LibGit2::CredentialAcquireCb
      ->(out_cred : LibGit2::Credential*, url : LibC::Char*, username : LibC::Char*, allowed : LibC::UInt, payload : Void*) {
        session     = Box(Session).unbox(payload)
        credentials = session.credentials

        mask     = allowed.to_u32
        from_url = username.null? ? nil : String.new(username)
        resolved = credentials.username || from_url || "git"

        if (mask & TYPE_USERNAME) != 0
          LibGit2.credential_username_new(out_cred, resolved)
        elsif session.attempts >= MAX_ATTEMPTS
          EAUTH
        else
          session.attempts += 1
          credentials.provide(out_cred, url.null? ? "" : String.new(url), resolved, mask)
        end
      }
    end
  end

  class Credentials::Default < Credentials
    def provide(out_cred : LibGit2::Credential*, url : String, username : String, allowed : UInt32) : LibC::Int
      return PASSTHROUGH if (allowed & TYPE_DEFAULT) == 0
      LibGit2.credential_default_new(out_cred)
    end
  end

  class Credentials::UserPass < Credentials
    def initialize(@user : String, @password : String)
    end

    def username : String?
      @user
    end

    def provide(out_cred : LibGit2::Credential*, url : String, username : String, allowed : UInt32) : LibC::Int
      return PASSTHROUGH if (allowed & TYPE_USERPASS) == 0
      LibGit2.credential_userpass_plaintext_new(out_cred, @user, @password)
    end
  end

  class Credentials::SshKey < Credentials
    def initialize(@user : String, @private_key : String, @public_key : String? = nil, @passphrase : String? = nil)
    end

    def username : String?
      @user
    end

    def provide(out_cred : LibGit2::Credential*, url : String, username : String, allowed : UInt32) : LibC::Int
      return PASSTHROUGH if (allowed & TYPE_SSH_KEY) == 0
      LibGit2.credential_ssh_key_new(out_cred, @user, Native.pointer(@public_key), @private_key, Native.pointer(@passphrase))
    end
  end

  class Credentials::SshAgent < Credentials
    def initialize(@user : String = "git")
    end

    def username : String?
      @user
    end

    def provide(out_cred : LibGit2::Credential*, url : String, username : String, allowed : UInt32) : LibC::Int
      return PASSTHROUGH if (allowed & TYPE_SSH_KEY) == 0
      LibGit2.credential_ssh_key_from_agent(out_cred, @user)
    end
  end
end
