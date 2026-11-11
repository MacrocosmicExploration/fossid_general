let
    Columns = {"scan_key", "scan_code"},
    CurrentRows = Table.SelectColumns(ScansBase, Columns),
    HistoricalRows = Table.SelectColumns(ScanHistoryBase, Columns),
    Combined = Table.Distinct(Table.Combine({CurrentRows, HistoricalRows})),
    RegisteredCodes = BusinessUnits[BU],
    WithSuggestion = Table.AddColumn(
        Combined, "SuggestedBU",
        each
            let
                Code = if [scan_code] = null then "" else Text.Upper(Text.Trim([scan_code])),
                Prefix =
                    if Text.Contains(Code, "_") then Text.BeforeDelimiter(Code, "_")
                    else null
            in
                if List.Contains(RegisteredCodes, Prefix) then Prefix else null,
        type nullable text
    ),
    Grouped = Table.Group(WithSuggestion, {"scan_key"}, {
        {"ObservedScanCodes", each
            Text.Combine(List.Sort(List.Distinct(List.RemoveNulls([scan_code]))), " | "),
            type text},
        {"SuggestedBU", each
            let Choices = List.Distinct(List.RemoveNulls([SuggestedBU]))
            in if List.Count(Choices) = 1 then Choices{0} else null,
            type nullable text}
    }),
    Joined = Table.NestedJoin(
        Grouped, {"scan_key"}, ScanOwnership, {"scan_key"},
        "ApprovedMapping", JoinKind.LeftOuter
    ),
    Expanded = Table.ExpandTableColumn(
        Joined, "ApprovedMapping", {"ApprovedBU"}, {"ApprovedBU"}
    ),
    WithReviewState = Table.AddColumn(
        Expanded, "ReviewState",
        each if [ApprovedBU] = null then "Needs ownership review" else "Mapped",
        type text
    ),
    Result = Table.Sort(WithReviewState, {{"scan_key", Order.Ascending}})
in
    Result
