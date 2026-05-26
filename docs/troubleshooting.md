# Troubleshooting

## sqlite3.exe was not found

Install SQLite and add `sqlite3.exe` to `PATH`, or place `sqlite3.exe` at:

```text
tools\sqlite3.exe
```

## No template thread was found

Create one normal chat in Codex Desktop first. The tool copies Desktop tool metadata from an existing visible conversation.

## Restored chats do not appear immediately

Switch projects in Codex Desktop or restart the app. If Codex was open during restore, it may have cached the old list.

## Chinese or non-English titles look wrong

Use version `0.2.0` or newer. SQLite output is read as UTF-8 by the shared core module.

## I restored the wrong record

Use `Backups / Rollback` in the GUI, or use the CLI:

```powershell
powershell -ExecutionPolicy Bypass -File .\Restore-CodexHistory.ps1 -RollbackBackup "C:\path\to\backup"
```

Backups are not deleted automatically.
