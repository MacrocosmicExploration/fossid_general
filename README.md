# FossID Power BI finishing guide

Start with [01 — Automatic BU and model setup](docs/01_APPROVED_BU_AND_MODEL.md).
Then follow [02 — Page filters](docs/02_PAGE_FILTERS.md) and
[03 — Group permissions and validation](docs/03_GROUP_PERMISSIONS.md).

These instructions extend an existing FossID dashboard with current scans,
daily scan history, employee mapping, and vulnerability/VEX tables. They do not
modify the FossID API pipeline.

## What is included

| Location | Purpose |
| --- | --- |
| [Model setup](docs/01_APPROVED_BU_AND_MODEL.md) | Automatic scan-code BU classification, migration from the old workbook approach, ApprovedBU, execution status, metadata cleanup, and relationships |
| [Page filters](docs/02_PAGE_FILTERS.md) | Exact fields and settings for all five pages, popup bookmarks, and CVSS 9.0-or-higher correction |
| [Permissions](docs/03_GROUP_PERMISSIONS.md) | Table-by-table role expressions, Entra groups, publishing, and validation |
| [Queries](powerbi/queries) | Complete Power Query M queries |
| [Functions](powerbi/functions) | Ownership validation and joins |
| [DAX measures](powerbi/dax) | Copy one measure definition at a time |
| [Role expressions](powerbi/roles) | Copy into Manage roles, not New measure |
| [Employee query](powerbi/reference/DimEmployee.pq) | Original working query preserved from this repository's previous README |
| [Tests](powerbi/tests) | Synthetic ownership checks and a separate RLS test model |

## Before copying code

- Power Query M: Transform data > New Source > Blank Query > Advanced Editor.
- DAX measures: main report window > Modeling > New measure, one definition at a time.
- Role filters: main report window > Modeling > Manage roles > DAX editor.
- A file name without its extension is the query name unless the guide says otherwise.
- Save a backup PBIX first. Keep the existing Scans, ScanHistory, and DimEmployee model names.
- Use GitHub's Raw view to copy a complete .pq or role-expression file.

## Data and access assumptions

The model uses Import storage mode and single-direction active relationships.
Recognized scan-code prefixes automatically determine BU ownership on refresh.
Power BI work-account/Entra role membership determines which BU a viewer may see.
No workbook and no per-scan assignments are required.
Current scan codes govern retained history; historical-only scans need consistent recognized prefixes.
Unknown or conflicting classifications remain InfoSec-only.
A mistaken but recognized prefix can misroute data, so naming accuracy is part of this access policy.

This is a public repository for generic code and instructions. Keep the actual
employee data, API credentials, JSON exports, and PBIX files
inside the work environment. The included fixtures are synthetic.

## Validation status

If you began the previous Excel workflow, use the short migration at the top of guide 01.
The existing employee mapping and role expressions can be retained.

The actual employee query was already confirmed working in the user's Power BI report.
All 15 Power Query files passed syntax validation with Microsoft's powerquery-parser 5.0.0.
Internal documentation links were checked, and the preserved employee query matches the original file byte for byte.
Syntax validation does not execute queries or prove the role design.
The new M/DAX and RLS setup require execution and acceptance testing in Power BI Desktop
and the tenant; this repository does not claim those tests have run in that environment.
Run [OwnershipSelfTests.pq](powerbi/tests/OwnershipSelfTests.pq), then complete the
role tests in the permissions guide before sharing the report.
