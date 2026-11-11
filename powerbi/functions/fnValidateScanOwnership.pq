(Mapping as table, AllowedBUs as list) as table =>
let
    Required = Table.SelectColumns(Mapping, {"scan_key", "ApprovedBU"}),
    AllowedTypesValid = List.AllTrue(
        List.Transform(AllowedBUs, each Value.Is(_, type text))
    ),
    Codes =
        if not AllowedTypesValid then
            error "ScanOwnership: registered BU codes must be text."
        else
            List.Transform(AllowedBUs, each Text.Upper(Text.Trim(_))),
    RegistryValid =
        not List.IsEmpty(Codes)
        and not List.Contains(Codes, "")
        and not List.Contains(Codes, "UNASSIGNED")
        and List.Count(Codes) = List.Count(List.Distinct(Codes)),
    TypesValid = List.AllTrue(
        List.Transform(
            Table.ToRecords(Required),
            each
                ([scan_key] = null or Value.Is([scan_key], type text))
                and ([ApprovedBU] = null or Value.Is([ApprovedBU], type text))
        )
    ),
    CheckedTypes =
        if TypesValid then Required
        else error "ScanOwnership: scan_key and ApprovedBU must be text; do not convert numeric IDs.",
    Cleaned = Table.TransformColumns(
        CheckedTypes,
        {
            {"scan_key", each
                if _ = null then null
                else if Text.Trim(_) = "" then null
                else Text.Trim(_), type nullable text},
            {"ApprovedBU", each
                if _ = null then null
                else if Text.Trim(_) = "" then null
                else Text.Upper(Text.Trim(_)), type nullable text}
        }
    ),
    // Excel tables can contain a completely empty entry row.
    NonEmpty = Table.SelectRows(
        Cleaned,
        each [scan_key] <> null or [ApprovedBU] <> null
    ),
    MissingKeys = Table.SelectRows(NonEmpty, each [scan_key] = null),
    Keys = List.RemoveNulls(NonEmpty[scan_key]),
    CanonicalKeys = List.Transform(Keys, each Text.Upper(_)),
    UnknownBUs = Table.SelectRows(
        NonEmpty,
        each [ApprovedBU] <> null and not List.Contains(Codes, [ApprovedBU])
    ),
    Result =
        if not RegistryValid then
            error "ScanOwnership: invalid or duplicate registered BU codes."
        else if not Table.IsEmpty(MissingKeys) then
            error "ScanOwnership: an ownership row has a BU but no scan_key."
        else if List.Count(CanonicalKeys) <> List.Count(List.Distinct(CanonicalKeys)) then
            error "ScanOwnership: duplicate scan_key, including case-only duplicates. Keep one row per scan."
        else if not Table.IsEmpty(UnknownBUs) then
            error "ScanOwnership: an ApprovedBU is not registered in BusinessUnits."
        else
            Table.TransformColumnTypes(
                NonEmpty,
                {{"scan_key", type text}, {"ApprovedBU", type nullable text}}
            )
in
    Result
