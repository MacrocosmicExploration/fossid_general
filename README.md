let
    Source = GLOBAL_EMPLOYEE,

    Typed = Table.TransformColumnTypes(
        Source,
        {
            {"EMPLOYEE_ID", type text},
            {"HIRE_DATE", type nullable date},
            {"TERMINATION_DATE", type nullable date}
        },
        "en-US"
    ),

    CleanIDs = Table.TransformColumns(
        Typed,
        {
            {
                "EMPLOYEE_ID",
                each if _ = null then null else Text.Trim(_),
                type text
            }
        }
    ),

    ValidIDs = Table.SelectRows(
        CleanIDs,
        each [EMPLOYEE_ID] <> null and [EMPLOYEE_ID] <> ""
    ),

    UniqueRows = Table.Distinct(ValidIDs),
    SourceColumns = Table.ColumnNames(UniqueRows),

    SelectAssignment = (Rows as table) as record =>
        let
            OpenAssignments = Table.SelectRows(
                Rows,
                each [TERMINATION_DATE] = null
            ),

            OpenCount = Table.RowCount(OpenAssignments),
            HireDates = Rows[HIRE_DATE],

            // Missing or placeholder dates cannot establish recency.
            DatesUsable =
                not List.Contains(HireDates, null)
                and not List.Contains(HireDates, #date(1900, 1, 1)),

            // Multiple open assignments remain unresolved.
            // When all assignments are closed, use the latest
            // hire date only if every row has a usable date.
            Candidates =
                if OpenCount > 0 then
                    OpenAssignments
                else if Table.RowCount(Rows) = 1 then
                    Rows
                else if DatesUsable then
                    let
                        LatestHire = List.Max(HireDates)
                    in
                        Table.SelectRows(
                            Rows,
                            each [HIRE_DATE] = LatestHire
                        )
                else
                    Rows,

            NeedsReview = Table.RowCount(Candidates) > 1,

            ConflictColumns =
                if NeedsReview then
                    List.Select(
                        SourceColumns,
                        (ColumnName) =>
                            List.Count(
                                List.Distinct(
                                    Table.Column(Candidates, ColumnName)
                                )
                            ) > 1
                    )
                else
                    {},

            // Keep only values shared by every candidate.
            // A blank versus a populated value also counts
            // as a conflict.
            EmployeeRecord =
                if not NeedsReview then
                    Candidates{0}
                else
                    Record.FromList(
                        List.Transform(
                            SourceColumns,
                            (ColumnName) =>
                                let
                                    Values = List.Distinct(
                                        Table.Column(
                                            Candidates,
                                            ColumnName
                                        )
                                    )
                                in
                                    if List.Count(Values) = 1 then
                                        Values{0}
                                    else
                                        null
                        ),
                        SourceColumns
                    ),

            ResultRecord = Record.Combine(
                {
                    EmployeeRecord,
                    [
                        EmployeeMappingStatus =
                            if NeedsReview then
                                "Needs review"
                            else
                                "Selected",

                        EmployeeMappingConflicts =
                            if NeedsReview then
                                Text.Combine(ConflictColumns, ", ")
                            else
                                null
                    ]
                }
            )
        in
            ResultRecord,

    Grouped = Table.Group(
        UniqueRows,
        {"EMPLOYEE_ID"},
        {
            {
                "SelectedAssignment",
                each SelectAssignment(_),
                type record
            }
        }
    ),

    // Preserve the source column types and add review fields.
    OutputTemplate = Table.AddColumn(
        Table.AddColumn(
            Table.FirstN(UniqueRows, 0),
            "EmployeeMappingStatus",
            each null,
            type nullable text
        ),
        "EmployeeMappingConflicts",
        each null,
        type nullable text
    ),

    Result = Table.FromRecords(
        Grouped[SelectedAssignment],
        Value.Type(OutputTemplate)
    )
in
    Result
