# Design Spec: SIPNAP Regulatory Export

Date: 2026-08-07

## Problem
Indonesian pharmacies are legally mandated to submit monthly reports for Narcotics,
Psychotropics, Precursors, and OOT (Obat-Obat Tertentu) to the Ministry of Health's
SIPNAP portal.

## Solution

### Schema Changes
- **Products**: Added `controlled_category` column ("Narkotika", "Psikotropika", "Prekursor", "OOT")

### SIPNAP Export Service
- `generateMonthlyReport(year, month)`: Calculates opening stock, received qty, sold qty, and closing stock for all controlled products
- `exportSipnapExcel(...)`: Formats formatted Excel table adhering to Ministry of Health SIPNAP columns

### UI Screen
- `SipnapReportScreen`: Period selector (month/year), preview datatable, and Excel export action
