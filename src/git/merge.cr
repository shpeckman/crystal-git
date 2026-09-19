# src/git/merge.cr
module Git
  enum MergeOutcome
    UpToDate
    FastForward
    Merged
    Conflicted
  end
end
