# Workspace Rules — Pharmacy Inventory Platform

## Strict Git & PR Workflow Rule

1. **NEVER push directly to `main` under any circumstances.**
2. **Every change MUST follow the feature branch → PR → CI pipeline:**
   - Create a feature branch: `git checkout -b feat/<name>` or `fix/<name>`
   - Commit and push to the feature branch: `git push origin feat/<name>`
   - Open a Pull Request: `gh pr create`
   - Wait for ALL GitHub Actions CI checks (`analyze-and-test`, `build-windows`, `build-android`, `secret-scan`, `verify-signatures`) to complete successfully (100% GREEN)
   - Merge the PR only after CI passes: `gh pr merge --squash`
3. **No Exceptions**: The agent must never push directly to `main` or skip PR/CI validation unless the user explicitly orders a bypass in writing for a specific command.
