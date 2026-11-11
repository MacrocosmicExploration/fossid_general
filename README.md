let
    Source = GLOBAL_EMPLOYEE,

    Typed = Table.TransformColumnTypes(
        Source,
        {
            {"EMPLOYEE_ID", type text},
            {"HIRE_DATE", type date},
            {"TERMINATION_DATE", type date}
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

    SelectAssignment = (Rows as table) as record =>
        let
            OpenAssignments = Table.SelectRows(
                Rows,
                each [TERMINATION_DATE] = null
            ),

            OpenCount = Table.RowCount(OpenAssignments),

            Selected =
                if OpenCount = 1 then
                    OpenAssignments{0}
                else if OpenCount > 1 then
                    error "Multiple open assignments for employee "
                        & Rows{0}[EMPLOYEE_ID]
                else if Table.RowCount(Rows) = 1 then
                    Rows{0}
                else
                    let
                        MissingHireDates = Table.SelectRows(
                            Rows,
                            each [HIRE_DATE] = null
                        ),

                        LatestHire =
                            if Table.RowCount(MissingHireDates) > 0 then
                                error "Missing hire date for employee "
                                    & Rows{0}[EMPLOYEE_ID]
                            else
                                List.Max(Rows[HIRE_DATE]),

                        LatestRows = Table.SelectRows(
                            Rows,
                            each [HIRE_DATE] = LatestHire
                        )
                    in
                        if Table.RowCount(LatestRows) = 1 then
                            LatestRows{0}
                        else
                            error "Tied latest assignments for employee "
                                & Rows{0}[EMPLOYEE_ID]
        in
            Selected,

    Grouped = Table.Group(
        ValidIDs,
        {"EMPLOYEE_ID"},
        {
            {
                "SelectedAssignment",
                each SelectAssignment(_),
                type record
            }
        }
    ),

    Result = Table.FromRecords(
        Grouped[SelectedAssignment],
        Value.Type(ValidIDs)
    )
in
    Result
