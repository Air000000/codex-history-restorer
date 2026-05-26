# Codex History Restorer

A small Windows tool for restoring local Codex Desktop chat history.

It helps when your old conversations still exist under `%USERPROFILE%\.codex`, but do not show up after switching accounts, updating Codex, importing sessions, or refreshing the sidebar.

The safest and easiest way to use it is to give this folder to an AI coding agent and let it run the restore carefully.

## Recommended: Let an AI Agent Use It

Copy this prompt into Codex, ChatGPT with local tools, Cursor, or another local coding agent:

```text
I lost Codex Desktop chat history after switching accounts or updating Codex.
Please use this local tool:

<path-to-codex-history-restorer>

Please:
1. Inspect the tool and my current Codex data first.
2. Run a dry run before changing anything.
3. Create or confirm a backup before restore.
4. Restore the missing chats.
5. If they still do not appear, handle provider/account mismatch and refresh the sidebar indexes.
6. Tell me what changed and where the backup is.
```

This works well because account-switch recovery is often a little fiddly: the chats may need database repair, JSONL metadata repair, and sidebar index refresh.

## Manual Use

### GUI

Double-click:

```text
run.bat
```

Then:

1. Choose the project.
2. Load records.
3. Preview hidden or old records.
4. Restore selected records.

Use `More tools...` for importing sessions, finding source folders, or rollback.

### CLI

List records:

```powershell
powershell -ExecutionPolicy Bypass -File .\Restore-CodexHistory.ps1 -ProjectRoot "D:\Projects\Example" -ListOnly
```

Preview:

```powershell
powershell -ExecutionPolicy Bypass -File .\Restore-CodexHistory.ps1 -ProjectRoot "D:\Projects\Example" -Numbers 1,2,3 -DryRun
```

Restore:

```powershell
powershell -ExecutionPolicy Bypass -File .\Restore-CodexHistory.ps1 -ProjectRoot "D:\Projects\Example" -Numbers 1,2,3
```

Import sessions from another Codex folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\Restore-CodexHistory.ps1 -ProjectRoot "D:\Projects\Example" -SourceSessionsDir "D:\Backup\.codex\sessions" -ImportSessions -RestoreAll
```

## What It Repairs

- hidden or old thread records in `state_5.sqlite`
- stale `session_meta` in `rollout-*.jsonl`
- account/provider mismatch after switching accounts
- missing Desktop tool metadata
- stale `session_index.jsonl` and `.codex-global-state.json`

The tool matches restored chats to your current visible Codex Desktop metadata, so old and new account formats can both be handled.

## Safety

- Runs locally only.
- Does not upload chat history.
- Creates a timestamped backup before writing.
- Supports dry run and rollback.

Backups are saved by default to:

```text
%USERPROFILE%\Documents\CodexHistoryRestorerBackups
```

Close Codex Desktop before large imports or rollback if possible.

## Requirements

- Windows
- PowerShell 5.1 or newer
- Codex Desktop
- `sqlite3.exe` in `PATH` or `tools\sqlite3.exe`
- At least one visible Codex Desktop conversation, used as a template

## Development

Run tests:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\Run-SmokeTests.ps1
```

Create release zip:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\package.ps1
```

More troubleshooting notes are in `docs\troubleshooting.md`.
