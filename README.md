# Codex History Restorer

![Platform](https://img.shields.io/badge/platform-Windows-0078D6)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE)
![GUI](https://img.shields.io/badge/UI-WinForms-2EA44F)
![Privacy](https://img.shields.io/badge/privacy-local--only-6F42C1)
![Release](https://img.shields.io/badge/release-zip-blue)
![License](https://img.shields.io/badge/license-MIT-yellow)

A local Windows tool for restoring Codex Desktop conversations that still exist on disk but no longer appear in the app.

It repairs Codex history metadata, imports recoverable `rollout-*.jsonl` files from old sessions or backups, and creates backups before writing anything.

## Download

Download the latest release zip from GitHub Releases, extract it, then double-click:

```text
run.bat
```

Do not download individual `.ps1` files unless you already know how to run PowerShell scripts. The release zip contains the GUI, CLI, docs, and helper files in the right layout.

## Quick Start

1. Double-click `run.bat`.
2. Click `Find recoverable records`.
3. If external sources are found, review the title previews and import the sources you trust.
4. Click `Select repairable`, or tick rows manually.
5. Click `Restore selected`.
6. Return to Codex Desktop, switch projects or restart Codex, then check the restored chats.

The GUI follows your Windows language by default and includes a language selector.

Most users do not need to change project settings. Leave project override empty to keep each chat under its original project.

## Privacy And Safety

This tool runs locally.

- It does not upload chat history.
- It does not call any network API.
- It does not delete backups automatically.
- It asks for confirmation before import, restore, or rollback.
- It creates a timestamped backup before writing.

Default backup location:

```text
%USERPROFILE%\Documents\CodexHistoryRestorerBackups
```

SQLite writes are grouped in transactions where possible. JSONL files are written through temporary files before replacement. If something still fails midway, use `Backups / Rollback` in the GUI.

## What It Can Fix

Codex Desktop stores local history in two places:

- `%USERPROFILE%\.codex\state_5.sqlite`
- `%USERPROFILE%\.codex\sessions\YYYY\MM\DD\rollout-*.jsonl`

When chats are still present locally but do not appear in Codex Desktop, the usual cause is incomplete or outdated metadata. The GUI marks these rows as `Needs repair`.

The tool can repair:

- Missing or outdated `thread_source`
- Mismatched `model_provider`
- Missing Desktop `dynamic_tools`
- Outdated JSONL first-line `session_meta`
- Old `updated_at_ms` values that keep restored chats low in the list
- Local sessions that exist in old `.codex\sessions`, archived sessions, VS Code/Cursor storage, or backup folders but are not yet in the current Codex database

## What It Cannot Fix

The tool cannot recover chats when:

- The local JSONL/session files are gone.
- The JSONL files are corrupted beyond parsing.
- The chat only exists in another account's cloud state.
- The current Codex app has no visible chat to use as a metadata template.
- A future Codex version changes the database format in an incompatible way.

If no template chat is found, create one normal chat in Codex Desktop, then run the tool again.

## Source Discovery

`Find recoverable records` scans common local locations:

- Current Codex sessions
- Codex archived sessions
- VS Code and Cursor global storage
- Documents and Downloads
- The configured backup folder
- A manually selected external sessions folder

External sources are not imported automatically. The GUI shows source type, counts, and title previews first; only checked sources are imported after confirmation.

## Advanced CLI Usage

For command-line use, double-click `run-cli.bat` or run:

```powershell
powershell -ExecutionPolicy Bypass -File .\Restore-CodexHistory.ps1
```

List candidate records for a project:

```powershell
powershell -ExecutionPolicy Bypass -File .\Restore-CodexHistory.ps1 -ProjectRoot "C:\path\to\your\project" -ListOnly
```

Preview a restore:

```powershell
powershell -ExecutionPolicy Bypass -File .\Restore-CodexHistory.ps1 -ProjectRoot "C:\path\to\your\project" -Numbers 6,7,8 -DryRun
```

Restore selected records:

```powershell
powershell -ExecutionPolicy Bypass -File .\Restore-CodexHistory.ps1 -ProjectRoot "C:\path\to\your\project" -Numbers 6,7,8
```

Import JSONL files from another sessions folder, then repair them:

```powershell
powershell -ExecutionPolicy Bypass -File .\Restore-CodexHistory.ps1 -ProjectRoot "C:\path\to\your\project" -SourceSessionsDir "D:\path\to\backup\.codex\sessions" -ImportSessions -RestoreAll
```

List backups:

```powershell
powershell -ExecutionPolicy Bypass -File .\Restore-CodexHistory.ps1 -ListBackups
```

Rollback from a backup:

```powershell
powershell -ExecutionPolicy Bypass -File .\Restore-CodexHistory.ps1 -RollbackBackup "C:\Users\You\Documents\CodexHistoryRestorerBackups\codex-history-restore-backup-20260524-120000"
```

## CLI Options

| Option | Purpose |
| --- | --- |
| `-ProjectRoot` | Optional project folder override. Leave empty to keep original projects. |
| `-ListOnly` | List matching threads and exit. |
| `-Numbers` | Restore records by list number, e.g. `-Numbers 1,2,5`. |
| `-ThreadIds` | Restore records by Codex thread id. |
| `-RestoreAll` | Restore all matching listed records. |
| `-OnlyOld` | Only restore records marked as old metadata. |
| `-ListBackups` | List manifest-based backups. |
| `-RollbackBackup` | Restore files from a backup directory. |
| `-SourceSessionsDir` | External `sessions` folder containing `rollout-*.jsonl`. |
| `-ImportSessions` | Import JSONL files into the current Codex database before repairing. |
| `-BackupRoot` | Custom backup directory. |
| `-TemplateThreadId` | Use a specific visible Desktop thread as metadata template. |
| `-NoTouch` | Do not update `updated_at_ms`. Restored records may remain low in the UI list. |
| `-DryRun` | Preview actions without writing. |

## Requirements

- Windows PowerShell 5.1 or PowerShell 7+
- `sqlite3.exe` in `tools\sqlite3.exe` or available in `PATH`
- Codex Desktop with at least one visible conversation

The release does not bundle `sqlite3.exe`. See `tools\README.md` for where to place a portable copy.

## Project Files

- `run.bat`: normal GUI launcher
- `run-cli.bat`: CLI launcher
- `run-gui-hidden.vbs`: hides the PowerShell window when launching the GUI
- `Restore-CodexHistory-GUI.ps1`: WinForms GUI
- `Restore-CodexHistory.ps1`: CLI wrapper
- `CodexHistoryRestorer.Core.psm1`: shared restore/import/backup logic
- `scripts\package.ps1`: creates the release zip
- `tests\Run-SmokeTests.ps1`: fake `.codex` smoke tests

## Development

Run smoke tests:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\Run-SmokeTests.ps1
```

Create a release zip:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\package.ps1
```

The zip is written to `dist\`.

## Troubleshooting

See [docs/troubleshooting.md](docs/troubleshooting.md).
