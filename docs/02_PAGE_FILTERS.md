# 02 — Build the filter menus

Complete [01 — Model setup](01_APPROVED_BU_AND_MODEL.md) first.
This guide uses the existing five-page report and its filter-menu templates.

## 1. Create one standard dropdown slicer

Repeat these steps for each categorical field in the page tables below.

1. Open the report page and show its existing filter panel.
2. Insert a Slicer visual.
3. Drag the specified column into the slicer's Field well.
4. In Format visual > Slicer settings, choose Dropdown.
5. Turn Single select OFF. If Multi-select with CTRL appears, turn it OFF so users
   can select several scans with ordinary clicks.
6. Enable Search from the slicer's menu where available.
7. Set a clear title such as BU, Project, Scan Code, or Creator Supervisor.
8. Add it to the filter-panel group in View > Selection.
9. Start with no selection. Clear unintended copied selections.

UI labels vary slightly by Desktop version. Use the standard slicer rather than
switching to a preview slicer solely to follow an exact label.

For fields in DimEmployee, choose the actual source column:
- Creator Name: ACTIVEDIRECTORYDISPLAYNAME.
- Creator Department: your confirmed department column.
- Creator Supervisor: your confirmed supervisor column.
- Creator Location: your confirmed office/location name column.
- If using OFFICE_ID, call it Creator Office ID.

Those three organization column names cannot be inferred reliably from the schema
shared so far. No calculated columns are required merely to rename the slicer title.
Keep blanks available; a blank can mean missing data or an unresolved assignment.

## 2. Page 1 — Executive Overview

| Filter title | Field | Style |
| --- | --- | --- |
| BU | Scans[ApprovedBU] | Dropdown |
| Project | Projects[project_name] | Searchable dropdown |
| Creator Department | Confirmed DimEmployee department column | Dropdown |
| Creator Supervisor | Confirmed DimEmployee supervisor column | Searchable dropdown |
| Creator Location / Office ID | Confirmed DimEmployee location column | Dropdown |

Select each slicer, open Format > Edit interactions, and ensure it filters the
business KPI cards and pending-identification chart. Leave the shared extraction
timestamp independent of these selections.

If project names are reused, include project_code or project_key in the selector
rather than assuming a display name identifies one project.

## 3. Page 2 — Identification Worklist

| Filter title | Field | Style |
| --- | --- | --- |
| BU | Scans[ApprovedBU] | Dropdown |
| Project | Projects[project_name] | Searchable dropdown |
| Scan Code | Scans[scan_code] | Searchable multi-select dropdown |
| Creator Name | DimEmployee[ACTIVEDIRECTORYDISPLAYNAME] | Searchable dropdown |
| Creator Department | Confirmed DimEmployee department column | Dropdown |

Keep the worklist's existing pending-files-greater-than-zero visual filters.
A selected scan with no pending files can legitimately produce an empty worklist.
Test one known scan with pending files, then select several scans and verify the chart
and table show all qualifying selections.

## 4. Page 3 — Scan Operations & Data Quality

| Filter title | Field | Style |
| --- | --- | --- |
| BU | Scans[ApprovedBU] | Dropdown |
| Project | Projects[project_name] | Searchable dropdown |
| Scan Code | Scans[scan_code] | Searchable multi-select dropdown |
| Execution Status | Scans[ExecutionStatusFilter] | Dropdown |
| Creator Name | DimEmployee[ACTIVEDIRECTORYDISPLAYNAME] | Searchable dropdown |

Use the new ExecutionStatusFilter in Scans. A filter placed only on
ScanSnapshot[execution_status] would not flow backwards to Scans through the intended
single-direction relationship, so some scan-count cards would remain unchanged.

Check status-specific measures. For example, if Finished Scan Records uses
CALCULATE with a fixed FINISHED filter, choosing NEW on Scans should yield no finished
scans in that selection, rather than silently clearing the chosen scan scope.

UNKNOWN means no usable current execution status was available. It does not mean FINISHED.
No extra failed-files slicer is required initially; keep failure indicators in the visuals.

## 5. Page 4 — Progress Over Time

| Filter title | Field | Style |
| --- | --- | --- |
| Snapshot Date (UTC) | HistoryRuns[snapshot_date] | Between |
| BU | ScanHistory[ApprovedBU] | Dropdown |
| Project | ScanHistory[project_label] | Searchable dropdown |
| Scan Code | ScanHistory[scan_code] | Searchable multi-select dropdown |
| Creator Department | Confirmed DimEmployee department column | Dropdown |
| Creator Supervisor | Confirmed DimEmployee supervisor column | Searchable dropdown |

For the date slicer:
1. Add HistoryRuns[snapshot_date].
2. Open its field dropdown and choose snapshot_date, not Date Hierarchy.
3. Set the slicer style to Between.
4. Choose a range containing at least two observed dates to test net backlog change.

Do not use current Scans/Projects fields on this page. They would exclude or fail to
filter historical-only records. A renamed historical scan/project can have multiple
labels across snapshots; use its stable key when comparing across a rename.

The date slicer changes the selected history interval. It does not turn the latest
current-state pages into historical views.

With one observed date, net change remains blank. Missing endpoint records remain
missing, not zero. Do not label a disappearing scan's backlog as resolved.

Employee filters use current/latest-known creator attributes; they are not an
as-of employee assignment history.

## 6. Page 5 — Vulnerability & VEX Review

| Filter title | Field | Style |
| --- | --- | --- |
| BU | Scans[ApprovedBU] | Dropdown |
| Project | Projects[project_name] | Searchable dropdown |
| Scan Code | Scans[scan_code] | Searchable multi-select dropdown |
| VEX Status | VEXStatus[StatusLabel] | Dropdown |
| VEX Response | VulnerabilitySnapshot[VEX Response Display] | Dropdown |
| VEX Justification | VulnerabilitySnapshot[VEX Justification Display] | Dropdown |
| CVE | VulnerabilitySnapshot[cve] | Searchable dropdown |
| Component | VulnerabilitySnapshot[component_name] | Searchable dropdown |
| CVSS Score | VulnerabilitySnapshot[base_score] | Between |

If the popup is small, put BU/Project/Scan/VEX Status first and use a second aligned
column for the detailed finding filters. Avoid a separate severity slicer when CVSS
already expresses the intended score threshold.

Keep the CVSS slicer cleared by default. An active score selection narrows all finding
visuals it interacts with, including the total-occurrence cards.
The critical visuals additionally retain their 9.0-or-higher condition.
Blank scores mean unavailable, not zero severity.

Preserve the existing No status recorded category. Keep all VEX status lookup
categories on the status chart, including currently unused ones.

### Make each CVE a clickable NVD link

The existing CVE text can open its NVD detail page. No Python changes, NVD API key,
or additional visible column are needed.

1. In Power BI Desktop's main window, select the **VulnerabilitySnapshot** table.
   If you are in Power Query, use **Close & Apply** first.
2. Select **New column** and paste the entire contents of
   [CVENVDURL.dax](../powerbi/dax/CVENVDURL.dax).
   This is a DAX calculated column, not a measure or a Power Query custom column.
3. Select the new **CVE NVD URL** column. Under **Column tools**, use data type
   **Text** and data category **Uncategorized** for this link-text method.
4. Select the Page 5 vulnerability **table visual**. Keep
   **VulnerabilitySnapshot[cve]** as its displayed CVE field.
5. Open **Format visual > Visual > Cell elements**. For **Apply settings to**,
   select the displayed **cve** column. Turn **Web URL** on; open its **fx**
   dialog if needed.
6. For **What field should we base this on?**, choose
   **VulnerabilitySnapshot[CVE NVD URL]**. If prompted, use format style
   **Field value** and summarization **First**. Each detail row must identify
   one CVE. Select **OK**.
7. Leave the URL helper out of the table's displayed columns. If you added it
   temporarily, remove it from the visual while retaining it in the model.
8. Open two different CVE links and verify that each NVD page has the matching
   identifier. Test again in the published report.

Alternative UI: in the visual's field list, open the displayed **cve** field's
menu and choose **Conditional formatting > Web URL**, then select the URL helper.
If Web URL is unavailable, confirm you selected the table visual and that the
helper column's data category is **Uncategorized**.

For example, `CVE-2021-44228` produces
`https://nvd.nist.gov/vuln/detail/CVE-2021-44228`.
The column trims whitespace and normalizes case. Blank values and values without
the `CVE-` prefix get no link. It does not validate the full identifier or check
whether NVD has published a record.

Future imported rows receive links on model refresh. This opens public NVD
information; it does not retrieve NVD scores into the model or change the
organization's FossID VEX assessment.

### Correct the threshold to include exactly 9.0

1. Open [CVSS9MeasureUpdates.dax](../powerbi/dax/CVSS9MeasureUpdates.dax).
2. In the Fields/Data pane, select each existing named measure and replace its
   definition with the corresponding block. Paste one at a time.
3. The existing measure names are retained to preserve visual bindings, even though
   their legacy names say Above 9.
4. Change the detail table's visual filter on base_score to
   is greater than or equal to 9.
5. Update the critical card/chart/table titles to CVSS 9.0 or higher.
6. Search the Filters pane for remaining greater-than-9 conditions.
7. Do not use the pipeline's existing cvss_gt_9 flag for this inclusive threshold;
   it intentionally means strictly greater than 9. Use base_score.
8. Do not add a page-level >=9 filter if the first two cards should continue to
   show all selected findings.

A response such as Update is not proof a patch was completed. Keep status, response,
and justification separate. Missing findings on a later run are not proof of remediation.
Collection coverage establishes successful retrieval, not assessment completion.

## 7. Limit long selector lists without changing relationship directions

To limit project or employee choices to records represented in the current selection:

1. Select that slicer.
2. Drag Filter Current Scan Count into Filters on this visual.
3. Set it to is greater than 0.

On Page 4 use Filter Historical Scan Count instead.
These measures are in [FilterAndValidationMeasures.dax](../powerbi/dax/FilterAndValidationMeasures.dax).

Use this especially for Creator Name so InfoSec does not scroll through every employee
in the directory. This is a usability filter; it does not replace RLS.
Do not add this filter to the VEX status chart if you want zero-count categories displayed.

Keep single-direction relationships. A project/employee list may not cascade from
every downstream finding selection; that is preferable to changing security propagation
casually. Test each intended interaction.

## 8. Update the popup's Open and Close bookmarks

For an overlay on the SAME report page:

1. Open View > Selection and View > Bookmarks.
2. Group the panel background, slicers, Close button, and Reset button.
3. Show the group and hide the Open button.
4. Select the panel group AND the Open button in Selection.
5. Create/update a bookmark named P1 Filters Open.
6. In the bookmark options: Data OFF, Display ON, Current page OFF, Selected visuals ON.
7. Hide the panel group and show the Open button.
8. Select the same objects and create/update P1 Filters Closed with the same options.
9. Set the Open button Action > Type = Bookmark > P1 Filters Open.
10. Set the Close button action to P1 Filters Closed.
11. Repeat using page-specific names for Pages 2–5.
12. In Desktop, Ctrl+click buttons to test; readers ordinarily click.

Data OFF prevents opening/closing the menu from restoring old slicer selections.
The hidden slicers still filter their page.

If your template instead uses a SEPARATE filter report page:
- Use View > Sync slicers to sync each filter slicer only to its corresponding
  content page. Check Sync for that pair; keep Visible off on the content page if desired.
- Give each page's pair its own sync group, not one global group.
- Use page-navigation buttons to move between the filter and content pages.
- Do not sync Page 4's historical scan/project/date fields to the current-state pages.

## 9. Add a Reset filters bookmark for each page

1. Clear that page's slicer selections. For Page 4, clear the date selection so newly
   imported dates are not excluded by a saved, fixed end date.
2. Select only that page's slicers.
3. Add a bookmark named P1 Reset Filters.
4. Use Data ON, Display OFF, Current page OFF, Selected visuals ON.
5. Assign it to that page's Reset button.
6. Repeat for every page.
7. Test that Reset clears filters without closing/opening the panel unexpectedly.

A Reset filters bookmark targets slicers; it is not a promise to reset every possible
chart selection, drill state, or personal bookmark. Click an empty chart area to clear
a selected bar while testing.

## 10. Check the completed menus

For each page:
- Select a known BU/project/scan and reconcile its totals against the same scope in FossID.
- Check multiple scan selections.
- Close/reopen the menu and confirm selections persist.
- Reset and confirm the page's default view returns.
- Check the creator filters and the intentional blanks from unresolved assignments.
- Ensure page-to-page navigation does not silently carry an unintended synced filter.
- Repeat after RLS is configured; slicers must only offer authorized business data.

The landing page needs navigation, page descriptions, and refresh information, not a
second global filter set.

Next: [03 — Group permissions](03_GROUP_PERMISSIONS.md).

## References

- [Hyperlink text in Power BI tables](https://learn.microsoft.com/en-us/power-bi/create-reports/power-bi-hyperlinks-in-tables#format-link-text-as-a-hyperlink)
- [Web URL conditional formatting](https://learn.microsoft.com/en-us/power-bi/create-reports/desktop-conditional-table-formatting#format-as-web-urls)
- [Slicer overview](https://learn.microsoft.com/en-us/power-bi/visuals/power-bi-visualization-slicers)
- [Report bookmarks](https://learn.microsoft.com/en-us/power-bi/create-reports/desktop-bookmarks)
- [Visual interactions](https://learn.microsoft.com/en-us/power-bi/create-reports/service-reports-visual-interactions)
