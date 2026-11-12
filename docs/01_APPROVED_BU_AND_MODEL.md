# 01 — Automatic BU classification and model setup

This guide now uses AUTOMATIC BU classification from scan_code. The previous Excel
per-scan approval workflow has been removed. No Python pipeline changes are required.

## Already at the old Step 5? Use this short migration

You do not need to copy scan keys or maintain an Excel mapping.

1. Keep your existing ScansBase and ScanHistoryBase queries.
2. Replace BusinessUnits with the updated [BusinessUnits.pq](../powerbi/queries/BusinessUnits.pq).
3. Create one new blank function query named fnBuildScanOwnership and paste
   [fnBuildScanOwnership.pq](../powerbi/functions/fnBuildScanOwnership.pq).
   It uses the fnValidateScanOwnership query you already created.
4. Replace ScanOwnership with [ScanOwnership.pq](../powerbi/queries/ScanOwnership.pq).
5. Replace OwnershipCandidates with [OwnershipCandidates.pq](../powerbi/queries/OwnershipCandidates.pq).
6. After those replacements, delete the now-unused OwnershipWorkbook and
   pOwnershipWorkbookPath QUERIES. The Excel file is no longer an input.
7. Refresh the previews, then continue at Step 6 below if you have not done it yet.
8. If using the optional self-test query, replace it with the updated file.

Keep the existing role expressions, field names, employee query, and relationships.
ApprovedBU is retained as a technical column name for compatibility; it now means
the automatically recognized BU, not a human approval. OwnershipStatus = Approved
is likewise a legacy label for successful automatic classification.
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

## 2. Define recognized BU prefixes once

The pipeline's scan_code contains names such as TMEA_example or ADS_example.
scan_key is the stable source/scan ID used for joins; do not parse it for a BU.

[BusinessUnits.pq](../powerbi/queries/BusinessUnits.pq) contains a small list:
~~~powerquery
Codes = {"TMEA", "ADS"}
~~~

This is configuration, not a list of scans or users. Add other recognized BU codes
when those BUs are onboarded. Every new scan with a recognized prefix is classified
automatically on refresh.

| scan_code | Automatic ApprovedBU |
| --- | --- |
| TMEA_example_1 | TMEA |
| ADS_example_2 | ADS |
| tmea_example_3 | TMEA |
| OTHER_example | null / Unassigned |
| example_without_known_prefix | null / Unassigned |
| TMEA (no underscore and description) | null / Unassigned |

The prefix before the first underscore must match a registered BU exactly.
Leading/trailing whitespace and casing are normalized. Missing or unrecognized
prefixes remain InfoSec-only once the RLS roles are in place.

The naming convention is the ownership signal in this design. A wrong but recognized
prefix can classify a scan into the wrong BU; Power BI cannot discover the intended
owner from that text alone. Correct scan naming in FossID matters. A trustworthy
FossID owning-group attribute could replace this signal later if it becomes available.

User access is separate: Power BI identifies the signed-in work account and applies
the role assigned to that user or their security group. No employee-to-login lookup
or per-scan approval is needed.

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

For each row:
1. Home > New Source > Blank Query.
2. Rename it exactly as shown.
3. Advanced Editor > replace the entire contents with the linked file > Done.
4. Do not include Markdown fences or a leading equals sign.
5. Turn Enable load OFF for these helpers. Leave source refresh enabled.

| Order | Query name | File to paste |
| --- | --- | --- |
| 1 | BusinessUnits | [BusinessUnits.pq](../powerbi/queries/BusinessUnits.pq) |
| 2 | fnValidateScanOwnership | [fnValidateScanOwnership.pq](../powerbi/functions/fnValidateScanOwnership.pq) |
| 3 | fnBuildScanOwnership | [fnBuildScanOwnership.pq](../powerbi/functions/fnBuildScanOwnership.pq) |
| 4 | ScanOwnership | [ScanOwnership.pq](../powerbi/queries/ScanOwnership.pq) |
| 5 | fnApplyScanOwnership | [fnApplyScanOwnership.pq](../powerbi/functions/fnApplyScanOwnership.pq) |
| 6 | fnWithExecutionStatus | [fnWithExecutionStatus.pq](../powerbi/functions/fnWithExecutionStatus.pq) |
| 7 | OwnershipCandidates (optional diagnostics) | [OwnershipCandidates.pq](../powerbi/queries/OwnershipCandidates.pq) |

Function queries display a function icon/input form; do not click Invoke to create
another query. ScanOwnership now builds its rows automatically from the base scans.
The validation function checks its generated keys and BU codes; it does not request approval.

## 5. Check automatic classification once

1. Open ScanOwnership and refresh its preview.
2. Confirm a few known TMEA and ADS examples have the expected ApprovedBU.
3. Optionally open OwnershipCandidates to see scan codes and BUAssignmentSource.
4. Continue to Step 6. There is no Excel copy/paste or per-scan assignment step.

For normal daily operation:
- A new TMEA_... scan is automatically TMEA at the next successful data refresh.
- A new ADS_... scan is automatically ADS.
- Unknown prefixes remain Unassigned and visible only to InfoSec.
- Fix incorrectly named current scans in FossID, then extract and refresh again.

Historical behavior:
- If a scan still exists in current ScansBase, its CURRENT scan_code determines access
  to that scan and all retained history. An unrecognized current name does not fall back
  to an old recognized prefix.
- For a historical-only scan, all retained names must resolve to the same recognized BU.
  Conflicting or incomplete prefixes remain Unassigned instead of guessing.
- The diagnostic query explains these exceptions. It is not an approval queue.

This is current classification for access control, not a reconstruction of historical
BU ownership. A valid-prefix rename can change access after the next successful refresh.
Restrict who can rename scans according to the organization's intended ownership process.

## 6. Replace the two existing model queries

Do not create new tables called Scans2 or ScanHistory2.

1. Select the ORIGINAL Scans query.
2. Open Advanced Editor and replace the entire query with [Scans.pq](../powerbi/queries/Scans.pq).
3. Select the ORIGINAL ScanHistory query.
4. Replace its entire query with [ScanHistory.pq](../powerbi/queries/ScanHistory.pq).
5. Keep Enable load ON for both.

Scans now contains:
- ApprovedBU: automatically recognized BU code or null.
- OwnershipStatus: Approved or Unassigned.
- ExecutionStatusFilter: normalized current execution status or UNKNOWN.

ScanHistory contains ApprovedBU and OwnershipStatus on every daily observation.
It preserves all historical rows. Ownership joins must not multiply or remove rows.
The current status merge rejects multiple current snapshots for the same scan.

The automatically resolved BU is applied to all historical rows of the scan. This is an
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
- BusinessUnits, ScanOwnership, OwnershipCandidates
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
4. Expect 31 rows with Passed = true.
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

- [Table.NestedJoin](https://learn.microsoft.com/en-us/powerquery-m/table-nestedjoin)
- [VALUES: DirectQuery RLS limitation](https://learn.microsoft.com/en-us/dax/values-function-dax)
