# 01 — ApprovedBU and model setup

Follow this guide in order. No Python pipeline changes are required.
The existing report already has Projects, Scans, ScanSnapshot, ScanHistory,
HistoryRuns, RefreshInfo, DimEmployee, VulnerabilitySnapshot, VulnerabilityCoverage,
and VEXStatus.

## 1. Save the report and check storage mode

1. Save a backup PBIX on the work computer.
2. In Model view, select each model table and inspect Properties > Advanced > Storage mode.
3. This guide assumes Import. If GLOBAL_EMPLOYEE was connected using DirectQuery,
   convert the employee dimension to Import when supported, or reimport it using Import
   before applying these role expressions. Do not assume the supplied RLS expressions work in DirectQuery.
4. Keep the original model-table names. Measures and relationships refer to them.

## 2. Create the internal ownership workbook

ApprovedBU means a scan's reviewed business-unit ownership. It is independent of
the creator's department and independent of the scan's editable name.

1. Open a new workbook in Excel.
2. Save it in an approved internal location as ScanOwnership.xlsx.
   Example local path: C:\FossIDDashboard\Security\ScanOwnership.xlsx.
   The actual file must remain outside this Git repository.
3. Create a worksheet named BusinessUnits.
4. In A1 enter BU. In A2 enter TMEA; in A3 enter ADS.
   These are examples for the initial rollout; include only actual recognized BU codes.
5. Select those cells, press Ctrl+T, and check My table has headers.
6. Under Table Design > Table Name, name the Excel table BusinessUnits.
7. Create a second worksheet named Ownership.
8. Put scan_key in A1 and ApprovedBU in B1.
9. Format both columns as Text.
10. Select A1:B2, press Ctrl+T, check My table has headers, and name the
    Excel table ScanOwnership. Leave the first data row empty initially.
11. Save and close Excel.

These must be Excel TABLE names, not just worksheet names.
Only authorized ownership maintainers should be able to edit the workbook.
Changing a mapping changes who can see the scan, including its retained history.

One scan_key can have one ApprovedBU in this initial design. A scan name, employee ID,
or project name is not a substitute for scan_key. If genuine shared scan ownership is
needed later, design an explicit access bridge; do not add duplicate keys to this workbook.

The workbook may retain keys for scans absent from the current inventory.
Blank ApprovedBU means not approved; it never means unrestricted access.
New scans remain unassigned until reviewed.

## 3. Preserve the existing source queries without breaking the model

Open Home > Transform data.

1. Right-click the existing Scans query > Duplicate. Name the duplicate ScansBase.
2. Right-click the existing ScanHistory query > Duplicate. Name the duplicate ScanHistoryBase.
3. Turn OFF Enable load on both duplicates.
4. Keep the original Scans and ScanHistory queries and their names.
5. In View > Query Dependencies, verify the base queries read the existing bundle/history
   sources and do not depend on the original Scans or ScanHistory queries.

Use Duplicate, not Reference. A Reference to Scans followed by replacing Scans with
a query that uses ScansBase would create a circular dependency. Renaming the original
Scans is also unnecessary and may redirect existing dependencies.

If you already added experimental ownership merges, make the base queries the
pre-ownership versions first. Do not connect either base query to ScanSecurityScope.

## 4. Add the supporting queries in this exact order

For each row below:

1. Home > New Source > Blank Query.
2. Rename it to the exact query name shown.
3. Open Advanced Editor, replace its entire contents with the linked file, then Done.
4. Do not include Markdown fences or a leading equals sign.
5. Set Enable load as shown. Leave source refresh enabled.

| Order | Query name | File to paste | Enable load |
| --- | --- | --- | --- |
| 1 | pOwnershipWorkbookPath | [pOwnershipWorkbookPath.pq](../powerbi/queries/pOwnershipWorkbookPath.pq) | Off |
| 2 | OwnershipWorkbook | [OwnershipWorkbook.pq](../powerbi/queries/OwnershipWorkbook.pq) | Off |
| 3 | BusinessUnits | [BusinessUnits.pq](../powerbi/queries/BusinessUnits.pq) | Off |
| 4 | fnValidateScanOwnership | [fnValidateScanOwnership.pq](../powerbi/functions/fnValidateScanOwnership.pq) | Off/function |
| 5 | ScanOwnership | [ScanOwnership.pq](../powerbi/queries/ScanOwnership.pq) | Off |
| 6 | fnApplyScanOwnership | [fnApplyScanOwnership.pq](../powerbi/functions/fnApplyScanOwnership.pq) | Off/function |
| 7 | fnWithExecutionStatus | [fnWithExecutionStatus.pq](../powerbi/functions/fnWithExecutionStatus.pq) | Off/function |
| 8 | OwnershipCandidates | [OwnershipCandidates.pq](../powerbi/queries/OwnershipCandidates.pq) | Off |

Edit the quoted path in pOwnershipWorkbookPath to match the real workbook.
It is a text-valued query, so a small text preview is expected.
Function queries display a function icon/input form; do not click Invoke to create another query.

If Power BI asks for privacy levels, use the company-approved settings for these internal
sources, commonly Organizational for an approved organizational boundary.
Do not disable privacy checks merely to bypass a Formula.Firewall error.

## 5. Review ownership suggestions and populate the workbook

OwnershipCandidates includes scans from today's inventory AND historical snapshots.
It compares the prefix before the first underscore with BusinessUnits.

Its SuggestedBU is only a suggestion. The output also includes all observed scan codes
for that key, so a renamed scan or conflicting names can be reviewed.

1. Open OwnershipCandidates and refresh its preview.
2. Review each scan with its owner/administrator using FossID.
3. Copy each approved scan_key into the Excel ScanOwnership table and enter its approved BU.
   You can copy preview cells for a small inventory; do not assume the first 1,000 preview
   rows are the complete inventory.
4. Leave uncertain ownership blank. Do not copy SuggestedBU wholesale into ApprovedBU.
5. Save and close the workbook.
6. Refresh the ScanOwnership and OwnershipCandidates previews.

For a larger inventory, use a temporary local export:
- Enable load for OwnershipCandidates temporarily.
- Close & Apply, open Table view, and use Copy table.
- Paste into an internal Excel review worksheet, preserving scan_key as Text.
- Approve the mapping into the separate ScanOwnership Excel table.
- Immediately turn Enable load back OFF for OwnershipCandidates before publishing.
- Check the copied row count against the table count; do not use an incomplete preview/export.

The approved workbook is an independent input, not a Power Query reference back to Scans.
This avoids a circular dependency.

Validation deliberately stops refresh for duplicate keys, case-only duplicate keys,
missing keys paired with a BU, unregistered BU codes, and numeric scan keys.
Completely empty Excel entry rows are ignored. A blank ApprovedBU is allowed and remains unassigned.

## 6. Replace the two existing model queries

Do not create new tables called Scans2 or ScanHistory2.

1. Select the ORIGINAL Scans query.
2. Open Advanced Editor and replace the entire query with [Scans.pq](../powerbi/queries/Scans.pq).
3. Select the ORIGINAL ScanHistory query.
4. Replace its entire query with [ScanHistory.pq](../powerbi/queries/ScanHistory.pq).
5. Keep Enable load ON for both.

Scans now contains:
- ApprovedBU: reviewed BU code or null.
- OwnershipStatus: Approved or Unassigned.
- ExecutionStatusFilter: normalized current execution status or UNKNOWN.

ScanHistory contains ApprovedBU and OwnershipStatus on every daily observation.
It preserves all historical rows. Ownership joins must not multiply or remove rows.
The current status merge rejects multiple current snapshots for the same scan.

The current approved BU is applied to all historical rows of the scan. This is an
access policy; it does not claim to reconstruct historical BU ownership.

## 7. Add the security scope and sanitize run metadata

1. Create a blank query named ScanSecurityScope.
2. Paste [ScanSecurityScope.pq](../powerbi/queries/ScanSecurityScope.pq).
3. Enable load for it. Do NOT create model relationships for this table.
4. Replace the existing HistoryRuns query with [HistoryRuns.pq](../powerbi/queries/HistoryRuns.pq).
5. Replace the existing RefreshInfo query with [RefreshInfo.pq](../powerbi/queries/RefreshInfo.pq).
6. Keep Enable load ON for HistoryRuns and RefreshInfo.

ScanSecurityScope records scan/project/creator/BU associations across current and
historical data. Role expressions use it to restrict project and employee lists.

HistoryRuns retains run_id, snapshot_date, observed_at_utc, and extraction_finished_utc.
RefreshInfo retains run_id and the two extraction timestamps.
Stored global inventory counts are deliberately omitted. Compute counts from secured facts.
Common run dates/timestamps are intentionally shared metadata.

If a custom visual used a removed manifest count, replace it with a measure over Scans,
ScanHistory, or the relevant secured fact. Do not restore a global count to fix that visual.

## 8. Finalize employee fields and query loading

Keep the already-working DimEmployee query. Its previous code is preserved in
[reference/DimEmployee.pq](../powerbi/reference/DimEmployee.pq); no need to paste it again.

In DimEmployee, add Home > Choose Columns after its final result step. Keep:
- EMPLOYEE_ID
- ACTIVEDIRECTORYDISPLAYNAME
- The actual source columns you need for department, supervisor, and location
- EMPLOYEE_STATUS, if useful
- EmployeeMappingStatus and EmployeeMappingConflicts

The exact department/supervisor/location column names have not been confirmed.
Inspect the source headers and choose the real columns; do not paste invented names.
OFFICE_ID can be used, but title that filter Creator Office ID unless you have an office-name lookup.
Do not discard the review flags. Blank disputed values mean unresolved attribution.

Disable Enable load for:
- GLOBAL_EMPLOYEE and any raw employee copies
- ScansBase, ScanHistoryBase, FossIDBundle, HistoryBundles
- OwnershipWorkbook, BusinessUnits, ScanOwnership, OwnershipCandidates
- EmployeeDuplicateCheck, EmployeeAssignmentReview, Errors in DimEmployee,
  and any other temporary diagnostic/staging queries

A query can still supply another query while its own Enable load is off.
Simply hiding a table in the model is not a security control.

## 9. Close & Apply and verify relationships

Keep all key/employee-ID fields as Text, including leading zeros.
Use active, single-direction filtering from the one side to the many side.

| One side | Many side |
| --- | --- |
| Projects[project_key] | Scans[project_key] |
| DimEmployee[EMPLOYEE_ID] | Scans[creator_username] |
| DimEmployee[EMPLOYEE_ID] | ScanHistory[creator_username] |
| Scans[scan_key] | ScanSnapshot[scan_key] |
| Scans[scan_key] | VulnerabilitySnapshot[scan_key] |
| Scans[scan_key] | VulnerabilityCoverage[scan_key] |
| HistoryRuns[run_id] | ScanHistory[run_id] |
| VEXStatus[StatusKey] | VulnerabilitySnapshot[VEX Status Key] |

Use one-to-many for the current snapshot relationship, even if currently one row per scan.
Do not relate current Scans or Projects directly to ScanHistory.
Do not create relationships for ScanSecurityScope or RefreshInfo.
Remove automatically detected relationships that conflict with this design.
Do not turn on bidirectional filtering to make slicer lists shrink.

Employee filters attribute history to the creator's current/latest-known employee record,
not to their department as of the scan date. Project/scan history still comes from each snapshot.

## 10. Run ownership function checks

1. In Power Query, create a blank query named OwnershipSelfTests.
2. Paste [OwnershipSelfTests.pq](../powerbi/tests/OwnershipSelfTests.pq).
3. Refresh the preview.
4. Expect 18 rows with Passed = true.
5. If any test fails, inspect Detail before continuing.
6. Keep Enable load OFF for this test query.

These tests exercise the actual M functions with synthetic inputs. They do not test DAX,
relationships, Entra membership, or Power BI Service permissions.

## 11. Add the new measures

Return to the main report window.

Open [FilterAndValidationMeasures.dax](../powerbi/dax/FilterAndValidationMeasures.dax).
For each definition, Modeling > New measure, then copy one definition including its name
and equals sign. Do not paste the entire multi-measure file into one formula.

Format count measures as Whole number. Format Dashboard Extraction Finished UTC as:
~~~text
dd MMM yyyy HH:mm "UTC"
~~~

Use that timestamp measure directly, without a Date Hierarchy.
The other diagnostic measures can live on a temporary validation page.

Then continue with [02 — Page filters](02_PAGE_FILTERS.md).

## References

- [Excel.Workbook](https://learn.microsoft.com/en-us/powerquery-m/excel-workbook)
- [Table.NestedJoin](https://learn.microsoft.com/en-us/powerquery-m/table-nestedjoin)
- [VALUES: DirectQuery RLS limitation](https://learn.microsoft.com/en-us/dax/values-function-dax)
