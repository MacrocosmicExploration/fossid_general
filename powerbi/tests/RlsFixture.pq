let
    // Synthetic role-filter fixture for a separate PBIX. No production connections.
    // ApprovedBU values represent classifier outputs; automatic classification is tested separately.
    Scans = #table(
        type table [scan_key = text, scan_code = text, project_key = nullable text,
            creator_username = nullable text, ApprovedBU = nullable text],
        {
            {"demo:a1", "TMEA_example_1", "project:a", "000001", "TMEA"},
            {"demo:b1", "ADS_example_1", "project:b", "000002", "ADS"},
            {"demo:u1", "UNKNOWN_example", "project:u", "000003", null},
            {"demo:a2", "TMEA_unknown_creator", null, "009999", "TMEA"},
            {"demo:b2", "ADS_shared_creator", "project:shared", "000004", "ADS"},
            {"demo:a3", "TMEA_example_3", "project:shared", "000004", "TMEA"}
        }
    ),
    ScanHistory = #table(
        type table [run_id = text, scan_key = text, scan_code = text,
            project_key = nullable text, creator_username = nullable text, ApprovedBU = nullable text],
        {
            {"run:1", "demo:a1", "TMEA_old_name", "project:a", "000001", "TMEA"},
            {"run:2", "demo:a1", "TMEA_example_1", "project:a", "000001", "TMEA"},
            {"run:2", "demo:b1", "ADS_example_1", "project:b", "000002", "ADS"},
            {"run:2", "demo:u1", "UNKNOWN_example", "project:u", "000003", null},
            {"run:2", "demo:a2", "TMEA_unknown_creator", null, "009999", "TMEA"},
            {"run:2", "demo:b2", "ADS_shared_creator", "project:shared", "000004", "ADS"},
            {"run:2", "demo:a3", "ADS_previous_name", "project:shared", "000004", "TMEA"},
            {"run:1", "demo:h1", "TMEA_history_only", "project:h", "000005", "TMEA"}
        }
    ),
    Projects = #table(type table [project_key = text, project_name = text], {
        {"project:a", "Example A"},
        {"project:b", "Example B"},
        {"project:u", "Unassigned example"},
        {"project:shared", "Shared example"},
        {"project:h", "Historical example"},
        {"project:unused", "Unused example"}
    }),
    DimEmployee = #table(type table [EMPLOYEE_ID = text, CreatorLabel = text], {
        {"000001", "Example creator A"},
        {"000002", "Example creator B"},
        {"000003", "Unassigned creator"},
        {"000004", "Shared creator"},
        {"000005", "Historical creator"},
        {"000006", "Unrelated creator"}
    }),
    ScanSnapshot = #table(type table [scan_key = text, total = number], {
        {"demo:a1", 10}, {"demo:b1", 10}, {"demo:u1", 10},
        {"demo:a2", 10}, {"demo:b2", 10}, {"demo:a3", 10},
        {"demo:orphan", 10}
    }),
    VulnerabilitySnapshot = #table(
        type table [scan_key = text, finding_key = text, cve = text, base_score = nullable number],
        {
            {"demo:a1", "finding:a1", "DEMO-A1", 9.0},
            {"demo:b1", "finding:b1", "DEMO-B1", 9.1},
            {"demo:u1", "finding:u1", "DEMO-U1", 10.0},
            {"demo:a2", "finding:a2", "DEMO-A2", 8.9},
            {"demo:b2", "finding:b2", "DEMO-B2", null},
            {"demo:a3", "finding:a3", "DEMO-A3", 9.5},
            {"demo:orphan", "finding:orphan", "DEMO-ORPHAN", 10.0}
        }
    ),
    VulnerabilityCoverage = Table.SelectColumns(Scans, {"scan_key"}),
    HistoryRuns = #table(type table [run_id = text, snapshot_date = date], {
        {"run:1", #date(2026, 1, 1)}, {"run:2", #date(2026, 1, 2)}
    })
in
    [
        Scans = Table.AddColumn(Scans, "OwnershipStatus",
            each if [ApprovedBU] = null then "Unassigned" else "Approved", type text),
        ScanHistory = Table.AddColumn(ScanHistory, "OwnershipStatus",
            each if [ApprovedBU] = null then "Unassigned" else "Approved", type text),
        Projects = Projects,
        DimEmployee = DimEmployee, ScanSnapshot = ScanSnapshot,
        VulnerabilitySnapshot = VulnerabilitySnapshot,
        VulnerabilityCoverage = VulnerabilityCoverage, HistoryRuns = HistoryRuns
    ]
