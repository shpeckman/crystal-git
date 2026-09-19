# spec/spec_helper.cr
require "spec"
require "../src/crystal-git"

# Initialize libgit2 global state before any specs run
Spec.before_suite do
  LibGit2.libgit2_init
end

# Clean up libgit2 global state after all specs finish
Spec.after_suite do
  LibGit2.libgit2_shutdown
end
