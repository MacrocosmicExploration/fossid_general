let
    // Diagnostic view only. These are automatic assignments, not an approval queue.
    Source = ScanOwnership,
    WithStatus = Table.AddColumn(
        Source,
        "ClassificationStatus",
        each if [ApprovedBU] = null then "Unassigned" else "Automatically assigned",
        type text
    ),
    Result = Table.Sort(WithStatus, {{"scan_key", Order.Ascending}})
in
    Result
