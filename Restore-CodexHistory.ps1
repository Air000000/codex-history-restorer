param(
    [string] $CodexHome = $(if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE ".codex" }),
    [string] $ProjectRoot = "",
    [string] $SourceSessionsDir = "",
    [string[]] $ThreadIds = @(),
    [int[]] $Numbers = @(),
    [string] $TemplateThreadId = "",
    [string] $BackupRoot = (Join-Path ([Environment]::GetFolderPath("MyDocuments")) "CodexHistoryRestorerBackups"),
    [switch] $ListOnly,
    [switch] $ImportSessions,
    [switch] $RestoreAll,
    [switch] $OnlyOld,
    [switch] $ListBackups,
    [string] $RollbackBackup = "",
    [switch] $DryRun,
    [switch] $NoTouch,
    [switch] $NoSidebarSync
)

$ErrorActionPreference = "Stop"
Import-Module (Join-Path $PSScriptRoot "CodexHistoryRestorer.Core.psm1") -Force -DisableNameChecking

function Select-CHRInteractive {
    param([object[]] $Rows)
    foreach ($row in $Rows) {
        "{0,3}. {1} [{2}] {3}" -f $row.Number, $row.Id, $row.Status, (Get-CHRShortTitle $row.Title)
    }
    Write-Host ""
    $answer = Read-Host "Enter numbers to restore, comma separated, or ALL"
    if ($answer -match "^\s*all\s*$") { return @($Rows) }
    $nums = @()
    foreach ($part in ($answer -split ",")) {
        $trim = $part.Trim()
        if (-not $trim) { continue }
        $nums += [int]$trim
    }
    return @($Rows | Where-Object { $nums -contains $_.Number })
}

$dbPath = Join-Path $CodexHome "state_5.sqlite"

if ($ListBackups) {
    $backups = @(Get-CHRBackups -BackupRoot $BackupRoot)
    if ($backups.Count -eq 0) {
        Write-CHRInfo "No backups found under $BackupRoot"
        exit 0
    }
    foreach ($backup in $backups) {
        "{0} [{1}] threads={2} manifest={3} {4}" -f $backup.CreatedAt.ToString("yyyy-MM-dd HH:mm:ss"), $backup.Operation, $backup.ThreadCount, $backup.HasManifest, $backup.Path
    }
    exit 0
}

if ($RollbackBackup) {
    Write-CHRInfo "Rolling back from: $RollbackBackup"
    $result = Restore-CHRBackup -BackupPath $RollbackBackup
    Write-CHRInfo "Restored $($result.Restored) file(s) from backup."
    exit 0
}

if (-not (Test-Path -LiteralPath $dbPath)) {
    throw "Codex database not found: $dbPath"
}

$interactive = -not ($ListOnly -or $ImportSessions -or $RestoreAll -or $ThreadIds.Count -gt 0 -or $Numbers.Count -gt 0 -or $DryRun)
if ($interactive) {
    Write-Host ""
    Write-Host "Codex History Restorer"
    Write-Host "This tool repairs local Codex Desktop history metadata. It does not upload anything."
    Write-Host ""
    $inputProject = Read-Host "Project root to attach histories to, or Enter for all projects"
    if ($inputProject) { $ProjectRoot = $inputProject }
    $inputSource = Read-Host "External sessions folder to import, or Enter to skip"
    if ($inputSource) {
        $SourceSessionsDir = $inputSource
        $ImportSessions = $true
    }
}

$projectDbCwd = ConvertTo-CHRDbCwd -Path $ProjectRoot
$projectJsonCwd = ConvertTo-CHRJsonCwd -Path $ProjectRoot
$template = Get-CHRTemplate -Database $dbPath -RequestedThreadId $TemplateThreadId

Write-CHRInfo "Codex home: $CodexHome"
Write-CHRInfo "Template thread: $($template.Id)"
Write-CHRInfo "Current model provider: $($template.ModelProvider)"
if ($ProjectRoot) { Write-CHRInfo "Project root: $projectJsonCwd" }
$envInfo = Test-CHREnvironment -CodexHome $CodexHome
if ($envInfo.DesktopRunning) {
    Write-CHRInfo "Warning: Codex Desktop appears to be running. Close it before large imports when possible."
}

if ($ImportSessions) {
    if (-not $SourceSessionsDir) { throw "-ImportSessions requires -SourceSessionsDir." }
    $scan = Test-CHRImportSessions -Database $dbPath -SessionsDir $SourceSessionsDir
    if ($DryRun) {
        Write-CHRInfo "Dry run import scan: scanned=$($scan.Scanned) importable=$($scan.Importable) existing=$($scan.Existing) invalid=$($scan.Invalid)"
    } else {
        $importBackup = New-CHRBackup -Database $dbPath -JsonlPaths @() -BackupRoot $BackupRoot -Operation "import" -CodexHome $CodexHome -ProjectRoot $projectJsonCwd
        Write-CHRInfo "Pre-import database backup created: $importBackup"
        $result = Import-CHRJsonlSessions -Database $dbPath -CodexHome $CodexHome -SessionsDir $SourceSessionsDir -ProjectDbCwd $projectDbCwd -ProjectJsonCwd $projectJsonCwd -Template $template
        Write-CHRInfo "Imported $(@($result.Imported).Count) new JSONL session file(s). Existing=$($result.Existing) Invalid=$($result.Invalid)."
        if (-not $NoSidebarSync) {
            $sync = Sync-CHRSidebarState -Database $dbPath -CodexHome $CodexHome -CurrentModelProvider $template.ModelProvider
            Write-CHRInfo "Sidebar index synced: threads=$($sync.ThreadCount) provider=$($sync.ModelProvider)"
        }
    }
}

$rows = @(Get-CHRThreadRows -Database $dbPath -ProjectDbCwd $projectDbCwd -CurrentModelProvider $template.ModelProvider -OldOnly:$OnlyOld)
if ($rows.Count -eq 0) {
    Write-CHRInfo "No matching threads found."
    exit 0
}

if ($ListOnly) {
    foreach ($row in $rows) {
        "{0,3}. {1} [{2}] {3}" -f $row.Number, $row.Id, $row.Status, (Get-CHRShortTitle $row.Title)
    }
    exit 0
}

$selected = @()
if ($RestoreAll) { $selected = @($rows) }
foreach ($number in $Numbers) {
    $match = $rows | Where-Object { $_.Number -eq $number } | Select-Object -First 1
    if (-not $match) { throw "No listed thread number: $number" }
    $selected += $match
}
foreach ($id in $ThreadIds) {
    $match = $rows | Where-Object { $_.Id -eq $id } | Select-Object -First 1
    if (-not $match) { throw "No listed thread id: $id" }
    $selected += $match
}
if ($interactive -and $selected.Count -eq 0) {
    $selected = Select-CHRInteractive -Rows $rows
}
$selected = @($selected | Sort-Object Id -Unique)
if ($selected.Count -eq 0) {
    Write-CHRInfo "No threads selected."
    exit 0
}

Write-Host ""
Write-Host "Selected threads:"
foreach ($row in $selected) {
    "  {0} {1}" -f $row.Id, (Get-CHRShortTitle $row.Title)
}

if ($DryRun) {
    Write-CHRInfo "Dry run only. No files were changed."
    exit 0
}

$pathsToBackup = Get-CHRRolloutPaths -Database $dbPath -Rows $selected
$backup = New-CHRBackup -Database $dbPath -JsonlPaths $pathsToBackup -BackupRoot $BackupRoot -Operation "restore" -CodexHome $CodexHome -ProjectRoot $projectJsonCwd -Rows $selected
Write-CHRInfo "Backup created: $backup"

Invoke-CHRSqlite -Database $dbPath -Sql "pragma wal_checkpoint(full);" | Out-Null
$changed = Repair-CHRThreads -Database $dbPath -Rows $selected -ProjectDbCwd $projectDbCwd -ProjectJsonCwd $projectJsonCwd -Template $template -NoTouch:$NoTouch
if (-not $NoSidebarSync) {
    $sync = Sync-CHRSidebarState -Database $dbPath -CodexHome $CodexHome -CurrentModelProvider $template.ModelProvider
    Write-CHRInfo "Sidebar index synced: threads=$($sync.ThreadCount) provider=$($sync.ModelProvider)"
}

Write-Host ""
Write-CHRInfo "Restored $(@($changed).Count) thread(s)."
Write-CHRInfo "Backup: $backup"
Write-CHRInfo "Switch projects in Codex Desktop or restart the app if the sidebar does not refresh."
