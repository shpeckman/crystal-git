# src/git/commands.cr
module Git
  module Commands
    MUTABLE_STATES  = StateSet.flags(Clean, Merge, Revert, RevertSequence, Cherrypick, CherrypickSequence)
    SEQUENCE_STATES = StateSet.flags(Merge, Revert, RevertSequence, Cherrypick, CherrypickSequence)
    REBASE_STATES   = StateSet.flags(Rebase, RebaseInteractive, RebaseMerge)
    CLEAN_ONLY      = StateSet.flags(Clean)
  end
end

require "./commands/index"
require "./commands/history"
require "./commands/refs"
require "./commands/integrate"
require "./commands/stash"
require "./commands/remote"
require "./commands/query"
