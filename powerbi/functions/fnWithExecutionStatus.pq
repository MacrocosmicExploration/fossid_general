(ScanRows as table, SnapshotRows as table) as table =>
let
    Base = Table.RemoveColumns(ScanRows, {"ExecutionStatusFilter"}, MissingField.Ignore),
    ScanKeys = Base[scan_key],
    ScanKeysValid = List.AllTrue(
        List.Transform(ScanKeys, each
            if not Value.Is(_, type text) then false else Text.Trim(_) <> "")
    ),
    CheckedScans =
        if not ScanKeysValid then error "Scans: scan_key must be nonblank text."
        else if List.Count(ScanKeys) <>
            List.Count(List.Distinct(List.Transform(ScanKeys, each Text.Upper(_)))) then
            error "Scans: expected one current row per scan_key."
        else Base,
    StatusRows = Table.SelectColumns(SnapshotRows, {"scan_key", "execution_status"}),
    SnapshotKeys = StatusRows[scan_key],
    SnapshotKeysValid = List.AllTrue(
        List.Transform(SnapshotKeys, each
            if not Value.Is(_, type text) then false else Text.Trim(_) <> "")
    ),
    CheckedStatus =
        if not SnapshotKeysValid then
            error "ScanSnapshot: scan_key must be nonblank text."
        else if List.Count(SnapshotKeys) <>
            List.Count(List.Distinct(List.Transform(SnapshotKeys, each Text.Upper(_)))) then
            error "ScanSnapshot: multiple current snapshots for one scan; do not merge history here."
        else StatusRows,
    Joined = Table.NestedJoin(
        CheckedScans, {"scan_key"},
        CheckedStatus, {"scan_key"},
        "StatusMatch", JoinKind.LeftOuter
    ),
    Expanded = Table.ExpandTableColumn(
        Joined, "StatusMatch", {"execution_status"}, {"ExecutionStatusFilter"}
    ),
    Normalized = Table.TransformColumns(
        Expanded,
        {{"ExecutionStatusFilter", each
            if _ = null then "UNKNOWN"
            else if Text.Trim(Text.From(_)) = "" then "UNKNOWN"
            else Text.Upper(Text.Trim(Text.From(_))), type text}}
    ),
    Result =
        if Table.RowCount(Normalized) <> Table.RowCount(CheckedScans) then
            error "Execution-status join changed the number of scans."
        else Normalized
in
    Result
