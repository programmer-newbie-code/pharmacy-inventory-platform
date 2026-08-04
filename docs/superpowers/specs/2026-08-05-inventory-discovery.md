# Inventory discovery UX

## Problem

The inventory search only refreshes after submit or manually tapping refresh.
When a query has no matches, the screen shows the same empty-catalog message and
does not offer a direct recovery action.

## Scope

- Refresh search results 300ms after typing stops.
- Ignore stale responses when a newer query has started.
- Explain which query has no matches and provide a localized clear action.
- Keep the existing product query, permissions, and stock aggregation policy.

## Acceptance criteria

- Typing a query does not issue one database request per keystroke.
- A no-result query shows the query text and a clear-search action.
- Clearing the query restores the full product list.
- Existing inventory and add-product workflows remain unchanged.

## Non-goals

- No change to product matching semantics or database schema.
- No new filter policy in this increment.
