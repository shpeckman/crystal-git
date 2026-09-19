# src/crystal-git.cr
require "./git/libgit2"

module Git
  VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify }}
end
