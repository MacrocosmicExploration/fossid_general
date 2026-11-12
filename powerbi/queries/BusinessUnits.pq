let
    // Configure recognized BU codes once. No scan keys or user identities belong here.
    Codes = {"TMEA", "ADS"},
    Normalized = List.Transform(Codes, each Text.Upper(Text.Trim(_))),
    Checked =
        if List.IsEmpty(Normalized) or List.Contains(Normalized, "") then
            error "BusinessUnits: configure at least one nonblank BU code."
        else if List.Count(Normalized) <> List.Count(List.Distinct(Normalized)) then
            error "BusinessUnits: duplicate BU codes."
        else if List.Contains(Normalized, "UNASSIGNED") then
            error "BusinessUnits: UNASSIGNED is reserved for unclassified scans."
        else Normalized,
    Result = Table.FromRows(
        List.Transform(Checked, each {_}),
        type table [BU = text]
    )
in
    Result
