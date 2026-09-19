# src/crystal-git.cr
require "./git/libgit2"
require "./git/libgit2_ext"
require "./git/error"
require "./git/library"
require "./git/oid"
require "./git/native"
require "./git/credentials"
require "./git/flags"
require "./git/status"
require "./git/merge"
require "./git/stash"
require "./git/conflict"
require "./git/state"
require "./git/value"
require "./git/transaction"
require "./git/undo"
require "./git/worktree"
require "./git/snapshot"
require "./git/repo"
require "./git/command"
require "./git/commands"
require "./git/stream"

module Git
  VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify }}
end
