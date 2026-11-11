let
    Columns = {"scan_key", "project_key", "creator_username", "ApprovedBU"},
    CurrentRows = Table.SelectColumns(Scans, Columns),
    HistoricalRows = Table.SelectColumns(ScanHistory, Columns),
    Combined = Table.Combine({CurrentRows, HistoricalRows}),
    Typed = Table.TransformColumnTypes(Combined, {
        {"scan_key", type text},
        {"project_key", type nullable text},
        {"creator_username", type nullable text},
        {"ApprovedBU", type nullable text}
    }),
    Result = Table.Distinct(Typed)
in
    Result
