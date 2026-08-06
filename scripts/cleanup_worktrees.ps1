# Cleanup local git worktrees and merged branches safely
Write-Host "Checking git worktrees..." -ForegroundColor Cyan
git worktree list

Write-Host "`nPruning stale worktrees..." -ForegroundColor Cyan
git worktree prune

Write-Host "`nFetching latest origin main..." -ForegroundColor Cyan
git checkout main
git pull origin main

Write-Host "`nPruning remote-tracking branches no longer on origin..." -ForegroundColor Cyan
git fetch --prune

Write-Host "`nDone! Repository is clean and synchronized with main." -ForegroundColor Green
