let
    Source = OwnershipWorkbook{[Item = "ScanOwnership", Kind = "Table"]}[Data],
    Result = fnValidateScanOwnership(Source, BusinessUnits[BU])
in
    Result
