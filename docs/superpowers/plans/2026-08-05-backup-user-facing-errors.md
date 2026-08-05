# Backup user-facing error states plan

1. Add localized backup/restore/Drive status messages and placeholders.
2. Add safe Drive exception mapping for configuration, permission, and unknown
   failures; remove raw exception rendering from BackupScreen.
3. Extend backup screen widget coverage for safe localized failure states.
4. Run generation, analyzer, coverage, Windows build, PR CI, and post-merge main
   CI. Real Google OAuth smoke testing remains an external credential decision.
