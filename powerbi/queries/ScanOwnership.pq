let
    // Automatic classification on refresh. No workbook or per-scan approval.
    Result = fnBuildScanOwnership(
        ScansBase,
        ScanHistoryBase,
        BusinessUnits[BU]
    )
in
    Result
