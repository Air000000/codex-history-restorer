# tools

Optional location for a portable `sqlite3.exe`.

Codex History Restorer looks for SQLite in this order:

1. `tools\sqlite3.exe`
2. `sqlite3.exe` from the system `PATH`

The repository does not bundle SQLite by default. If you publish a release zip with SQLite included, also include the matching SQLite license or source notice.
