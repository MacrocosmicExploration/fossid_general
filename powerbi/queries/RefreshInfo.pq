let
    Source = Table.FromRecords(
        {FossIDBundle[manifest]},
        {"run_id", "extraction_started_utc", "extraction_finished_utc"}
    ),
    ToUTC = (Value as nullable text) as nullable datetime =>
        if Value = null then null
        else DateTimeZone.RemoveZone(
            DateTimeZone.SwitchZone(DateTimeZone.FromText(Value), 0)
        ),
    Result = Table.TransformColumns(Source, {
        {"run_id", each Text.From(_), type text},
        {"extraction_started_utc", ToUTC, type nullable datetime},
        {"extraction_finished_utc", ToUTC, type nullable datetime}
    })
in
    Result
