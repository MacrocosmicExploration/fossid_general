let
    Source = OwnershipWorkbook{[Item = "BusinessUnits", Kind = "Table"]}[Data],
    Selected = Table.SelectColumns(Source, {"BU"}),
    TypesValid = List.AllTrue(
        List.Transform(Selected[BU], each _ = null or Value.Is(_, type text))
    ),
    CheckedTypes =
        if TypesValid then Selected
        else error "BusinessUnits: BU codes must be stored as text in Excel.",
    Cleaned = Table.TransformColumns(
        CheckedTypes,
        {{"BU", each if _ = null then null else Text.Upper(Text.Trim(_)), type nullable text}}
    ),
    NonBlank = Table.SelectRows(Cleaned, each [BU] <> null and [BU] <> ""),
    Result =
        if Table.IsEmpty(NonBlank) then
            error "BusinessUnits: register at least one approved BU code."
        else if List.Count(List.Distinct(NonBlank[BU])) <> Table.RowCount(NonBlank) then
            error "BusinessUnits: duplicate BU codes after normalization."
        else if List.Contains(NonBlank[BU], "UNASSIGNED") then
            error "BusinessUnits: UNASSIGNED is reserved; leave unapproved ownership blank."
        else
            NonBlank
in
    Result
