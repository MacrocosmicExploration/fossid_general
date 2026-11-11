let
    // Shared run/date metadata only; no global inventory counts.
    Source = Table.SelectColumns(HistoryBundles, {
        "run_id", "snapshot_date", "observed_at_utc", "extraction_finished_utc"
    }),
    Result = Table.TransformColumnTypes(Source, {
        {"run_id", type text},
        {"snapshot_date", type date},
        {"observed_at_utc", type datetime},
        {"extraction_finished_utc", type datetime}
    })
in
    Result
