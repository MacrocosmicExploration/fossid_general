(ScanRows as table, Mapping as table) as table =>
let
    // Mapping must come from the validated ScanOwnership query.
    Base = Table.RemoveColumns(
        ScanRows,
        {"ApprovedBU", "OwnershipStatus"},
        MissingField.Ignore
    ),
    ValidKeys = List.AllTrue(
        List.Transform(Base[scan_key], each
            if not Value.Is(_, type text) then false
            else Text.Trim(_) <> "")
    ),
    Map = Table.SelectColumns(Mapping, {"scan_key", "ApprovedBU"}),
    MapKeys = Map[scan_key],
    ValidMapKeys = List.AllTrue(
        List.Transform(MapKeys, each
            if not Value.Is(_, type text) then false
            else Text.Trim(_) <> "")
    ),
    CanonicalMapKeys =
        if ValidMapKeys then List.Transform(MapKeys, each Text.Upper(Text.Trim(_)))
        else error "Ownership join: mapping has an invalid scan_key.",
    CheckedMap =
        if List.Count(CanonicalMapKeys) <> List.Count(List.Distinct(CanonicalMapKeys)) then
            error "Ownership join: duplicate mapping keys would multiply rows."
        else Map,
    CheckedBase =
        if ValidKeys then Base
        else error "Ownership join: every source scan_key must be nonblank text.",
    Joined = Table.NestedJoin(
        CheckedBase, {"scan_key"},
        CheckedMap, {"scan_key"},
        "OwnershipMatch", JoinKind.LeftOuter
    ),
    Expanded = Table.ExpandTableColumn(
        Joined, "OwnershipMatch", {"ApprovedBU"}, {"ApprovedBU"}
    ),
    CheckedCount =
        if Table.RowCount(Expanded) <> Table.RowCount(CheckedBase) then
            error "Ownership join changed the number of source rows."
        else Expanded,
    Typed = Table.TransformColumnTypes(
        CheckedCount, {{"ApprovedBU", type nullable text}}
    ),
    Result = Table.AddColumn(
        Typed, "OwnershipStatus",
        each if [ApprovedBU] = null then "Unassigned" else "Approved",
        type text
    )
in
    Result
