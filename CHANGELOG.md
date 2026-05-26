# Changelog

## Unreleased

- Match restored records to the current template thread's `model_provider` instead of hard-coding `codex_local_access`.
- Refresh `session_index.jsonl` and `.codex-global-state.json` after restore/import so account-switch recoveries appear in the Desktop sidebar.
- Include sidebar state files in restore/import backups.
- List user Desktop threads regardless of `has_user_event`, matching newer Codex Desktop behavior.

## 0.2.0

- Added WinForms GUI workflow for normal Windows users.
- Added automatic source discovery for `rollout-*.jsonl`.
- Added shared core module used by GUI and CLI.
- Added manifest-based backups and rollback support.
- Added import dry-run scan reporting.
- Added project picker, search, status filtering, and thread details.
- Added release packaging and smoke tests.

## 0.1.0

- Initial CLI recovery workflow for Codex Desktop history metadata.
