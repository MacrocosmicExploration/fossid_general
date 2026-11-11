# 03 — Group permissions and validation

Complete [model setup](01_APPROVED_BU_AND_MODEL.md) before creating these roles.
This is an Import-model design. These files configure Power BI; they do not alter
FossID permissions or the API account's visibility.

## 1. Understand the access model

| Group example | RLS role | Scope |
| --- | --- | --- |
| SG-PBI-FossID-TMEA | TMEA_View | Approved TMEA scans and associated data |
| SG-PBI-FossID-ADS | ADS_View | Approved ADS scans and associated data |
| SG-PBI-FossID-InfoSec | InfoSec_All | All imported data, including unassigned records |

Use existing approved group names if available.
InfoSec is an explicit group assignment, not a department-name substring rule.
Creator attributes and scan-name prefixes do not grant access.

Each BU role has FIVE table filters:
- Scans and ScanHistory restrict current and historical facts independently.
- ScanSecurityScope restricts the association list.
- Projects and DimEmployee restrict their own rows using that association list.

A permitted scan may share a creator or project with another BU. Shared metadata is
visible to the BUs associated with that entity; other BU scan/finding rows remain blocked.
This is a creator/project metadata policy, not an HR-directory authorization system.
Keep only the necessary employee attributes in the model.

Unknown employees/projects may use the model's blank dimension member.
The dimension expressions permit that placeholder so an approved scan is not lost merely
because its employee is absent. Scan-level BU filters remain mandatory.

## 2. Create TMEA_View in Desktop

1. Return to the main report window.
2. Modeling > Manage roles > New.
3. Name the role TMEA_View.
4. Select the table named in the next table.
5. Choose the DAX editor and paste the complete expression from the linked file.
6. Validate the expression and repeat for all five tables.
7. Save.

| Table selected in Manage roles | Expression file |
| --- | --- |
| Scans | [TMEA ApprovedBU](../powerbi/roles/TMEA_View/ApprovedBU.dax) |
| ScanHistory | [TMEA ApprovedBU](../powerbi/roles/TMEA_View/ApprovedBU.dax) |
| ScanSecurityScope | [TMEA ApprovedBU](../powerbi/roles/TMEA_View/ApprovedBU.dax) |
| Projects | [TMEA Projects](../powerbi/roles/TMEA_View/Projects.dax) |
| DimEmployee | [TMEA DimEmployee](../powerbi/roles/TMEA_View/DimEmployee.dax) |

The ApprovedBU file is pasted separately onto THREE tables.
The other two expressions use the RLS-filtered ScanSecurityScope table.
Do not omit its BU rule.

Role files contain Boolean expressions only. They are not measures, and you do not
prefix them with a measure name or add them in Power Query.

Scans must actively filter ScanSnapshot, VulnerabilitySnapshot, and VulnerabilityCoverage.
ScanSecurityScope must remain disconnected; its expressions provide the lookup.
Do not add bidirectional security relationships to compensate for omitted rules.

## 3. Create ADS_View

Create a fresh role named ADS_View, or duplicate TMEA_View and replace its rules
with the corresponding files below.

| Table selected in Manage roles | Expression file |
| --- | --- |
| Scans | [ADS ApprovedBU](../powerbi/roles/ADS_View/ApprovedBU.dax) |
| ScanHistory | [ADS ApprovedBU](../powerbi/roles/ADS_View/ApprovedBU.dax) |
| ScanSecurityScope | [ADS ApprovedBU](../powerbi/roles/ADS_View/ApprovedBU.dax) |
| Projects | [ADS Projects](../powerbi/roles/ADS_View/Projects.dax) |
| DimEmployee | [ADS DimEmployee](../powerbi/roles/ADS_View/DimEmployee.dax) |

If ADS currently has no mapped scans, an empty ADS view is expected.
Do not broaden its rule to make the page look populated.

## 4. Create InfoSec_All

1. Create a NEW role named InfoSec_All.
2. On Scans, paste [InfoSec_All/Scans.dax](../powerbi/roles/InfoSec_All/Scans.dax).
3. Leave every other table unrestricted in this role.
4. Save.

Do not duplicate a BU role and accidentally retain filters on ScanHistory,
ScanSecurityScope, Projects, or DimEmployee.

## 5. Audit the loaded model

Use Model view to verify that the only loaded tables are the intended business
tables, the minimized employee dimension, ScanSecurityScope, the sanitized run metadata,
and static lookup/measure tables.

- Raw GLOBAL_EMPLOYEE, base scans/history, ownership suggestions, and error-review queries
  must not be loaded. Hiding them is insufficient.
- No disconnected table may hold unfiltered copies of projects, employee rows, findings,
  or stored all-BU inventory totals.
- HistoryRuns and RefreshInfo should contain only the columns listed in guide 01.
- A custom calculated summary table is materialized at refresh; it does not automatically
  inherit later viewer RLS. Remove it or explicitly secure it before sharing.
- Static VEX status labels and shared refresh dates/timestamps are intentionally available
  to all authorized report consumers.
- Do not distribute a full-data PBIX to restricted consumers as an access-control method.

## 6. Test in Desktop

Create a temporary validation page with:
- Filter Current Scan Count
- Filter Historical Scan Count
- Security Test Finding Count
- Security Test Coverage Scan Count
- Security Test Visible BUs
- Unassigned Current Scans
- Unassigned Historical Scan Keys

All are in [FilterAndValidationMeasures.dax](../powerbi/dax/FilterAndValidationMeasures.dax).

Also add separate table visuals showing:
- Scans: scan_key, scan_code, ApprovedBU
- ScanHistory: scan_key, ApprovedBU
- Projects: project_key, project_name
- DimEmployee: EMPLOYEE_ID and display name
- ScanSecurityScope: scan_key, project_key, creator_username, ApprovedBU

These separate tables reveal metadata leakage that a combined scan visual can hide.

1. Clear report selections.
2. Modeling > View as > choose only TMEA_View.
3. Check all five report pages and the validation page.
4. Stop viewing, then repeat for ADS_View.
5. Repeat for InfoSec_All.
6. Test TMEA_View and ADS_View together: the intended result is their UNION.
7. Test InfoSec_All with a BU role: the intended result is full access.

Expected behavior:
- Each restricted role shows only its approved BU in scan/finding/history rows.
- Project and creator lists contain only associated records, plus a possible blank placeholder.
- Restricted views exclude unassigned scans, even if their names begin with that BU.
- Historical-only scans remain available to the authorized BU.
- An approved scan with an unmapped employee remains visible.
- Clearing slicers and pressing Reset does not broaden RLS.
- Remove filters from every visual; RLS still applies.
- Inspect enabled exports as well as visuals.

If only one BU exists in production, use the synthetic fixture below to test actual
cross-BU separation before relying on the design for the next rollout.

## 7. Optional separate synthetic RLS model

Use a NEW EMPTY PBIX, not the production report. This tests the exact role files without
requiring real employee or vulnerability data.

1. Open Power BI Desktop > New report > Transform data.
2. Create a blank query named RlsFixture.
3. Paste [RlsFixture.pq](../powerbi/tests/RlsFixture.pq). Disable Enable load.
4. Create these blank queries, pasting the expression in Advanced Editor:

| Query name | Entire M expression |
| --- | --- |
| Scans | RlsFixture[Scans] |
| ScanHistory | RlsFixture[ScanHistory] |
| Projects | RlsFixture[Projects] |
| DimEmployee | RlsFixture[DimEmployee] |
| ScanSnapshot | RlsFixture[ScanSnapshot] |
| VulnerabilitySnapshot | RlsFixture[VulnerabilitySnapshot] |
| VulnerabilityCoverage | RlsFixture[VulnerabilityCoverage] |
| HistoryRuns | RlsFixture[HistoryRuns] |

5. Enable load for these eight tables.
6. Add ScanSecurityScope using its actual [query file](../powerbi/queries/ScanSecurityScope.pq).
7. Close & Apply and create the relationships in guide 01, excluding VEXStatus
   (not needed for this fixture). Do not relate current Scans/Projects to ScanHistory.
8. Create the three roles using the actual role files.
9. Add the validation measures except Dashboard Extraction Finished UTC, since this
   empty test model has no RefreshInfo.
10. Add the separate tables described above; use CreatorLabel for the synthetic employee name.
11. Use View as for each role.

With no report filters, expected counts are:

| Role | Current scans | Distinct historical scans | Findings | Coverage scans | Unassigned current scans |
| --- | ---: | ---: | ---: | ---: | ---: |
| TMEA_View | 3 | 4 | 3 | 3 | 0 |
| ADS_View | 2 | 2 | 2 | 2 | 0 |
| TMEA_View + ADS_View | 5 | 6 | 5 | 5 | 0 |
| InfoSec_All | 6 | 7 | 7 | 6 | 1 |

Check these deliberate edge cases:
- demo:h1 is historical-only TMEA.
- demo:a2 is approved TMEA with no matching employee and a null project.
- demo:a3 has an ADS-looking name but approved TMEA ownership.
- demo:u1 looks like TMEA but has no approval and remains InfoSec-only.
- demo:orphan has no parent Scans row and must not appear in either BU role's findings.
- Creator 000004 and project:shared are shared, but scans remain BU-restricted.
- project:unused and employee 000006 are excluded from both BU roles.
- Blank dimension members may appear as placeholders; they must not expose unrelated rows.

The fixture also includes scores 8.9, 9.0, 9.1, 9.5, 10.0, and null for manual threshold
inspection. A CVSS >=9 count across all findings is 5 for InfoSec, 2 for TMEA, and 1 for ADS.

These expected results are acceptance criteria, not a claim that the DAX engine was
executed by the repository author. Do not publish the fixture as the production dashboard.

## 8. Create or reuse Microsoft Entra security groups

Prefer approved existing groups with the correct membership.
If new groups are needed, ask the identity administrator to create the three groups
from section 1. If you have the required tenant permissions:

1. Open the Microsoft Entra admin center.
2. Entra ID > Groups > All groups > New group.
3. Group type: Security.
4. Enter the approved group name and a description of the data it grants.
5. Membership type: Assigned for this initial manual setup.
6. Add a responsible owner and the intended members.
7. Leave Microsoft Entra roles can be assigned to the group OFF; directory-role
   assignment is not needed for a Power BI RLS group.
8. Create and repeat for the other groups.

A Microsoft 365/Teams group is not interchangeable with an Entra security group for
Power BI RLS membership. Keep InfoSec membership explicitly managed.

## 9. Publish and connect groups to roles

1. In Desktop, Home > Publish.
2. Select the approved organizational workspace, not My workspace.
3. In the Power BI service, open that workspace.
4. Find the SEMANTIC MODEL, not just the report.
5. Select its ... menu > Security.
6. Select TMEA_View, add the TMEA Entra security group, and Save.
7. Repeat for ADS_View and InfoSec_All.
8. Use Test as role, then test actual non-editor viewer accounts.

The role assignment controls rows; it does not itself give someone access to the report.

Grant report access through one of these:
- Preferred: publish/update a Power BI app and add the approved groups to its audience.
  App audiences control which content appears; the RLS roles still control data.
- Alternatively: Workspace > Manage access > add the group with Viewer permission.
  This grants workspace viewing, so use an app when consumers should see only selected content.

Restricted consumers must not receive workspace Admin, Member, or Contributor access,
whether directly or through another group. Those edit roles bypass RLS.
InfoSec consumers can be Viewers too; InfoSec_All grants their full data scope.
Do not grant Build or reshare permissions unless needed for the intended use case.

Check the organization's licensing/capacity requirements with the Power BI administrator.
App/report access does not remove licensing requirements.

## 10. Verify actual identities and ongoing refresh

Test with:
- A TMEA-only viewer.
- An ADS-only viewer.
- An InfoSec viewer.
- A viewer with report access but no RLS assignment: secured data must not be usable.

Repeat the page, metadata-list, reset, and enabled-export checks.
Do not rely solely on testing as the report owner, who normally has edit access.

All assigned roles are additive. A person in TMEA and ADS sees both BUs; a person with
InfoSec_All sees all imported rows. Membership is the authorization source.

For refresh:
- Run the FossID pipeline first, then refresh the semantic model.
- The service needs access to the existing output/history sources, Snowflake, AND
  the ownership workbook. A file on the work laptop requires an appropriate running
  gateway and source configuration for scheduled service refresh.
- Use company-approved storage and credentials. A locally synced path is not automatically
  a cloud-accessible source.
- Ownership changes only take effect in this Import model after a successful refresh.
- A failed refresh leaves the previously loaded mapping/data in service. For an urgent
  access revocation, remove report/group access through the administrators rather than
  waiting for a broken data refresh.
- Review unassigned scans after each refresh; never auto-approve a naming prefix.

When adding another BU:
1. Register its code in the internal workbook.
2. Review and populate ownership mappings.
3. Create/reuse its Entra security group.
4. Copy a BU role, change its three ApprovedBU rules, and retain the metadata rules.
5. Refresh/publish, assign the group, and repeat the separation tests.

No Python code changes are needed just to add another BU.

## References

- [Power BI RLS setup and membership](https://learn.microsoft.com/en-us/fabric/security/service-admin-row-level-security)
- [RLS design guidance and additive roles](https://learn.microsoft.com/en-us/power-bi/guidance/rls-guidance)
- [Workspace roles](https://learn.microsoft.com/en-us/power-bi/collaborate-share/service-roles-new-workspaces)
- [Entra group management](https://learn.microsoft.com/en-us/entra/fundamentals/how-to-manage-groups)
- [VALUES and Import/DirectQuery restrictions](https://learn.microsoft.com/en-us/dax/values-function-dax)
