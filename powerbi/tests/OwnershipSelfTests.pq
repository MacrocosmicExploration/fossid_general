let
    // Synthetic data only. Run after creating all four function queries.
    BUs = {"TMEA", "ADS"},
    MapType = type table [scan_key = nullable text, ApprovedBU = nullable text],
    Scans = #table(type table [scan_key = text, scan_code = text], {
        {"demo:1", "ADS_misleading_name"},
        {"demo:2", "TMEA_unmapped_name"}
    }),
    Good = fnValidateScanOwnership(
        #table(MapType, {{"demo:1", " tmea "}}), BUs
    ),
    ExpectError = (Action as function) as logical =>
        let Attempt = try Action()
        in Attempt[HasError],
    Check = (Name as text, Action as function) as record =>
        let
            Attempt = try Action(),
            Passed = if Attempt[HasError] then false else Attempt[Value] = true,
            Detail =
                if Attempt[HasError] then Attempt[Error][Message]
                else if Passed then "Passed"
                else "Assertion returned false"
        in [Test = Name, Passed = Passed, Detail = Detail],
    Cases = {
        Check("BU normalization", () => Good{0}[ApprovedBU] = "TMEA"),
        Check("Missing mapping remains unassigned", () =>
            let T = fnApplyScanOwnership(Scans, Good)
            in T{1}[ApprovedBU] = null and T{1}[OwnershipStatus] = "Unassigned"),
        Check("Join uses the resolved BU for historical rows", () =>
            fnApplyScanOwnership(Scans, Good){0}[ApprovedBU] = "TMEA"),
        Check("Left join retains both scans", () =>
            Table.RowCount(fnApplyScanOwnership(Scans, Good)) = 2),
        Check("Empty mapping is allowed", () =>
            Table.RowCount(fnValidateScanOwnership(#table(MapType, {}), BUs)) = 0),
        Check("Empty input row is ignored by validator", () =>
            Table.RowCount(fnValidateScanOwnership(#table(MapType, {{null, null}}), BUs)) = 0),
        Check("Blank BU is not approval", () =>
            fnValidateScanOwnership(#table(MapType, {{"demo:1", " "}}), BUs){0}[ApprovedBU] = null),
        Check("Unregistered BU is rejected", () =>
            ExpectError(() => Table.RowCount(
                fnValidateScanOwnership(#table(MapType, {{"demo:1", "TYPO"}}), BUs)))),
        Check("Duplicate keys are rejected even for identical BU", () =>
            ExpectError(() => Table.RowCount(fnValidateScanOwnership(
                #table(MapType, {{"demo:1", "TMEA"}, {"demo:1", "TMEA"}}), BUs)))),
        Check("Case-only duplicate keys are rejected", () =>
            ExpectError(() => Table.RowCount(fnValidateScanOwnership(
                #table(MapType, {{"demo:1", "TMEA"}, {"DEMO:1", "ADS"}}), BUs)))),
        Check("Missing key with a BU is rejected", () =>
            ExpectError(() => Table.RowCount(
                fnValidateScanOwnership(#table(MapType, {{null, "TMEA"}}), BUs)))),
        Check("Numeric keys are rejected", () =>
            ExpectError(() => Table.RowCount(fnValidateScanOwnership(
                #table({"scan_key", "ApprovedBU"}, {{123, "TMEA"}}), BUs)))),
        Check("Empty BU registry is rejected", () =>
            ExpectError(() => Table.RowCount(
                fnValidateScanOwnership(#table(MapType, {}), {})))),
        Check("Join independently rejects duplicate mapping keys", () =>
            ExpectError(() => Table.RowCount(fnApplyScanOwnership(
                Scans, #table(MapType, {{"demo:1", "TMEA"}, {"demo:1", "ADS"}}))))),
        Check("History observations remain separate", () =>
            let
                History = #table(type table [scan_key = text, run_id = text], {
                    {"demo:1", "run-a"}, {"demo:1", "run-b"}
                }),
                T = fnApplyScanOwnership(History, Good)
            in Table.RowCount(T) = 2 and List.AllTrue(List.Transform(T[ApprovedBU], each _ = "TMEA"))),
        Check("Execution status normalized and missing status unknown", () =>
            let
                Snap = #table(type table [scan_key = text, execution_status = nullable text], {
                    {"demo:1", " finished "}
                }),
                T = fnWithExecutionStatus(Scans, Snap)
            in T{0}[ExecutionStatusFilter] = "FINISHED" and T{1}[ExecutionStatusFilter] = "UNKNOWN"),
        Check("Multiple current snapshots are rejected", () =>
            ExpectError(() => Table.RowCount(fnWithExecutionStatus(
                Scans,
                #table(type table [scan_key = text, execution_status = text], {
                    {"demo:1", "NEW"}, {"demo:1", "FINISHED"}
                })
            )))),
        Check("Empty scan inventory retains output schema", () =>
            let T = fnApplyScanOwnership(Table.FirstN(Scans, 0), Good)
            in Table.RowCount(T) = 0 and Table.HasColumns(T, {"ApprovedBU", "OwnershipStatus"}))
,
        Check("New current scan automatically classified", () =>
            let T = fnBuildScanOwnership(
                #table({"scan_key", "scan_code"}, {{"auto:1", "TMEA_example"}}),
                #table({"scan_key", "scan_code"}, {}), BUs)
            in T{0}[ApprovedBU] = "TMEA"),
        Check("Prefix normalization", () =>
            fnBuildScanOwnership(
                #table({"scan_key", "scan_code"}, {{"auto:1", " ads_example "}}),
                #table({"scan_key", "scan_code"}, {}), BUs){0}[ApprovedBU] = "ADS"),
        Check("Unknown prefix remains unassigned", () =>
            fnBuildScanOwnership(
                #table({"scan_key", "scan_code"}, {{"auto:1", "OTHER_example"}}),
                #table({"scan_key", "scan_code"}, {}), BUs){0}[ApprovedBU] = null),
        Check("Missing delimiter remains unassigned", () =>
            fnBuildScanOwnership(
                #table({"scan_key", "scan_code"}, {{"auto:1", "TMEA"}}),
                #table({"scan_key", "scan_code"}, {}), BUs){0}[ApprovedBU] = null),
        Check("Empty suffix remains unassigned", () =>
            fnBuildScanOwnership(
                #table({"scan_key", "scan_code"}, {{"auto:1", "TMEA_"}}),
                #table({"scan_key", "scan_code"}, {}), BUs){0}[ApprovedBU] = null),
        Check("Prefix match is exact", () =>
            fnBuildScanOwnership(
                #table({"scan_key", "scan_code"}, {{"auto:1", "TMEAX_example"}}),
                #table({"scan_key", "scan_code"}, {}), BUs){0}[ApprovedBU] = null),
        Check("Current prefix governs retained history", () =>
            fnBuildScanOwnership(
                #table({"scan_key", "scan_code"}, {{"auto:1", "ADS_new"}}),
                #table({"scan_key", "scan_code"}, {{"auto:1", "TMEA_old"}}), BUs){0}[ApprovedBU] = "ADS"),
        Check("Unrecognized current prefix does not fall back to old BU", () =>
            fnBuildScanOwnership(
                #table({"scan_key", "scan_code"}, {{"auto:1", "UNKNOWN_now"}}),
                #table({"scan_key", "scan_code"}, {{"auto:1", "TMEA_old"}}), BUs){0}[ApprovedBU] = null),
        Check("Consistent history-only scan is assigned automatically", () =>
            fnBuildScanOwnership(
                #table({"scan_key", "scan_code"}, {}),
                #table({"scan_key", "scan_code"}, {{"auto:1", "TMEA_old"}, {"auto:1", "TMEA_new"}}), BUs){0}[ApprovedBU] = "TMEA"),
        Check("Conflicting history-only prefixes remain unassigned", () =>
            fnBuildScanOwnership(
                #table({"scan_key", "scan_code"}, {}),
                #table({"scan_key", "scan_code"}, {{"auto:1", "TMEA_old"}, {"auto:1", "ADS_new"}}), BUs){0}[ApprovedBU] = null),
        Check("Incomplete history-only naming remains unassigned", () =>
            fnBuildScanOwnership(
                #table({"scan_key", "scan_code"}, {}),
                #table({"scan_key", "scan_code"}, {{"auto:1", "TMEA_old"}, {"auto:1", null}}), BUs){0}[ApprovedBU] = null),
        Check("Duplicate current records are rejected", () =>
            ExpectError(() => Table.RowCount(fnBuildScanOwnership(
                #table({"scan_key", "scan_code"}, {{"auto:1", "TMEA_a"}, {"auto:1", "ADS_b"}}),
                #table({"scan_key", "scan_code"}, {}), BUs)))),
        Check("Empty automatic inventory retains schema", () =>
            let T = fnBuildScanOwnership(
                #table({"scan_key", "scan_code"}, {}),
                #table({"scan_key", "scan_code"}, {}), BUs)
            in Table.RowCount(T) = 0 and Table.HasColumns(T, {"scan_key", "ApprovedBU"}))
    },
    Result = Table.FromRecords(
        Cases, type table [Test = text, Passed = logical, Detail = text]
    )
in
    Result
