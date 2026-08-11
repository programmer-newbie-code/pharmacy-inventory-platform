# Shift Supervisor Review

## Current-state evidence

`CashierShift` records expected/actual cash, discrepancy, and discrepancy
reason, but its only state is `open|closed`; no reviewer, review time, or
review note exists. `closeShift` tests prove discrepancy calculation, but no
supervisor review path is present. The approved roadmap requires close-shift
discrepancy and supervisor review.

## Scope

- Persist nullable reviewer ID, review timestamp, and review note on cashier
  shifts.
- Permit only an authenticated administrator to review a closed shift.
- Present review status and an admin review action in the shift screen.
- Preserve existing reconciliation mathematics and closed-shift history.
- Add schema migration and repository/widget tests.

## Non-goals

- Changing cash calculation, editing closed cash amounts, requiring a review
  before a new shift, or imposing a business approval threshold.
- Adding external signatures, payment integrations, or data deletion.

## Acceptance criteria

1. Existing databases migrate without data loss; historic shifts are simply
   unreviewed.
2. Only admins can review; open shifts cannot be reviewed.
3. A review stores acting admin ID, time, and optional note atomically.
4. UI shows unreviewed/reviewed state and supports keyboard/touch review for
   an authenticated admin.
5. Unit, widget, migration, analyzer, coverage, and Windows build gates pass.

## Platform, migration, and risk

Schema version increases by one and adds nullable columns to `cashier_shifts`.
Rollback is code-only; migrated nullable metadata is benign if a prior version
does not use it. This is shared Windows/Android behavior. The review is a
local audit marker, not a legally binding signature; retention policy remains
deferred.
