(CurrentScans as table, HistoricalScans as table, AllowedBUs as list) as table =>
let
    Codes = List.Transform(AllowedBUs, each Text.Upper(Text.Trim(_))),
    BUFromCode = (ScanCode as any) as nullable text =>
        let
            Clean = if Value.Is(ScanCode, type text)
                then Text.Upper(Text.Trim(ScanCode)) else "",
            HasDelimiter = Text.Contains(Clean, "_"),
            Prefix = if HasDelimiter then Text.Trim(Text.BeforeDelimiter(Clean, "_")) else null,
            Suffix = if HasDelimiter then Text.Trim(Text.AfterDelimiter(Clean, "_")) else ""
        in
            if Prefix <> null and Suffix <> "" and List.Contains(Codes, Prefix)
            then Prefix else null,
    SelectInput = (Rows as table, Current as logical) as table =>
        let
            Selected = Table.SelectColumns(Rows, {"scan_key", "scan_code"}),
            KeysValid = List.AllTrue(List.Transform(Selected[scan_key], each
                if not Value.Is(_, type text) then false
                else _ <> "" and Text.Trim(_) = _)),
            Checked =
                if KeysValid then Selected
                else error "BU classification: scan_key must be nonblank text without surrounding spaces.",
            Tagged = Table.AddColumn(Checked, "IsCurrent", each Current, type logical)
        in Tagged,
    CurrentRows = SelectInput(CurrentScans, true),
    HistoryRows = SelectInput(HistoricalScans, false),
    Combined = Table.Combine({CurrentRows, HistoryRows}),
    Resolve = (Rows as table) as record =>
        let
            Current = Table.SelectRows(Rows, each [IsCurrent]),
            CurrentCount = Table.RowCount(Current),
            Parsed = List.Transform(Rows[scan_code], each BUFromCode(_)),
            HistoricalChoices = List.Distinct(Parsed),
            HistoricalConsistent =
                List.Count(HistoricalChoices) = 1
                and not List.Contains(HistoricalChoices, null),
            BU =
                if CurrentCount > 1 then
                    error "BU classification: multiple current rows for one scan_key."
                else if CurrentCount = 1 then
                    BUFromCode(Current{0}[scan_code])
                else if HistoricalConsistent then
                    HistoricalChoices{0}
                else null,
            Source =
                if CurrentCount = 1 then
                    if BU = null then "Unrecognized current prefix"
                    else "Current scan_code prefix"
                else if BU <> null then
                    "Consistent historical prefixes"
                else
                    "Unknown or conflicting historical prefixes",
            Labels = List.Sort(List.Distinct(List.Select(
                Rows[scan_code], each Value.Is(_, type text)
            )))
        in
            [
                ApprovedBU = BU,
                BUAssignmentSource = Source,
                ObservedScanCodes = Text.Combine(Labels, " | ")
            ],
    Grouped = Table.Group(Combined, {"scan_key"}, {
        {"Resolved", each Resolve(_), type record}
    }),
    Expanded = Table.ExpandRecordColumn(Grouped, "Resolved", {
        "ApprovedBU", "BUAssignmentSource", "ObservedScanCodes"
    }),
    // Reuse key/registry validation. This table is generated, not maintained by a person.
    Validated = fnValidateScanOwnership(Expanded, Codes),
    Checked =
        if Table.RowCount(Validated) <> Table.RowCount(Expanded) then
            error "BU classification changed the number of distinct scan keys."
        else Expanded,
    Result = Table.TransformColumnTypes(Checked, {
        {"scan_key", type text}, {"ApprovedBU", type nullable text},
        {"BUAssignmentSource", type text}, {"ObservedScanCodes", type text}
    })
in
    Result
