let
    Owned = fnApplyScanOwnership(ScansBase, ScanOwnership),
    Result = fnWithExecutionStatus(Owned, ScanSnapshot)
in
    Result
