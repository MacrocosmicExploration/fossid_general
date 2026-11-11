let
    Source = Excel.Workbook(
        File.Contents(pOwnershipWorkbookPath),
        null,
        true
    )
in
    Source
