param(
    [string] $OutputRoot = (Join-Path $PSScriptRoot "..\test-output")
)

$ErrorActionPreference = "Stop"
Import-Module (Join-Path $PSScriptRoot "..\CodexHistoryRestorer.Core.psm1") -Force -DisableNameChecking

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw "ASSERT FAILED: $Message" }
}

function Write-JsonLine {
    param([string] $Path, [object] $Object)
    ($Object | ConvertTo-Json -Depth 20 -Compress) | Add-Content -LiteralPath $Path -Encoding UTF8
}

if (Test-Path -LiteralPath $OutputRoot) { Remove-Item -LiteralPath $OutputRoot -Recurse -Force }
New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null

$codexHome = Join-Path $OutputRoot ".codex"
$sessions = Join-Path $codexHome "sessions\2026\05\24"
New-Item -ItemType Directory -Path $sessions -Force | Out-Null
$db = Join-Path $codexHome "state_5.sqlite"
$globalState = Join-Path $codexHome ".codex-global-state.json"
$sessionIndex = Join-Path $codexHome "session_index.jsonl"

Invoke-CHRSqlite -Database $db -Sql @"
create table threads (
    id text primary key,
    rollout_path text not null,
    created_at integer not null,
    updated_at integer not null,
    source text not null,
    model_provider text not null,
    cwd text not null,
    title text not null,
    sandbox_policy text not null,
    approval_mode text not null,
    tokens_used integer not null default 0,
    has_user_event integer not null default 0,
    archived integer not null default 0,
    archived_at integer,
    git_sha text,
    git_branch text,
    git_origin_url text,
    cli_version text not null default '',
    first_user_message text not null default '',
    agent_nickname text,
    agent_role text,
    memory_mode text not null default 'enabled',
    model text,
    reasoning_effort text,
    agent_path text,
    created_at_ms integer,
    updated_at_ms integer,
    thread_source text,
    preview text not null default ''
);
create table thread_dynamic_tools (
    thread_id text not null,
    position integer not null,
    name text not null,
    description text not null,
    input_schema text not null,
    defer_loading integer not null default 0,
    namespace text,
    primary key(thread_id, position)
);
"@ | Out-Null

$templateId = "template-0001"
$oldId = "old-0001"
$project = [System.IO.Path]::GetFullPath((Join-Path $OutputRoot "ProjectA"))
New-Item -ItemType Directory -Path $project -Force | Out-Null
$dbCwd = ConvertTo-CHRDbCwd $project
$jsonCwd = ConvertTo-CHRJsonCwd $project
$templatePath = Join-Path $sessions "rollout-template-0001.jsonl"
$oldPath = Join-Path $sessions "rollout-old-0001.jsonl"

Write-JsonLine $templatePath ([pscustomobject]@{
    timestamp = "2026-05-24T00:00:00.000Z"
    type = "session_meta"
    payload = [pscustomobject]@{
        id = $templateId
        timestamp = "2026-05-24T00:00:00.000Z"
        cwd = $jsonCwd
        source = "vscode"
        thread_source = "user"
        model_provider = "openai"
        cli_version = "0.test"
        dynamic_tools = @([pscustomobject]@{ namespace = "codex_app"; name = "read_thread_terminal"; description = "test"; input_schema = "{}" })
    }
})
Write-JsonLine $oldPath ([pscustomobject]@{
    timestamp = "2026-05-24T00:01:00.000Z"
    type = "session_meta"
    payload = [pscustomobject]@{
        id = $oldId
        timestamp = "2026-05-24T00:01:00.000Z"
        cwd = $jsonCwd
        source = "vscode"
        model_provider = "codex_local_access"
        cli_version = "0.old"
    }
})

Invoke-CHRSqlite -Database $db -Sql "insert into threads(id,rollout_path,created_at,updated_at,source,model_provider,cwd,title,sandbox_policy,approval_mode,tokens_used,has_user_event,archived,cli_version,first_user_message,memory_mode,created_at_ms,updated_at_ms,thread_source,preview) values('template-0001',$(Quote-CHRSql $templatePath),1,1,'vscode','openai',$(Quote-CHRSql $dbCwd),'template','{}','on-request',0,0,0,'0.test','template','enabled',1000,1000,'user','template');" | Out-Null
Invoke-CHRSqlite -Database $db -Sql "insert into thread_dynamic_tools(thread_id,position,name,description,input_schema,defer_loading,namespace) values('template-0001',0,'read_thread_terminal','test','{}',0,'codex_app');" | Out-Null
Invoke-CHRSqlite -Database $db -Sql "insert into threads(id,rollout_path,created_at,updated_at,source,model_provider,cwd,title,sandbox_policy,approval_mode,tokens_used,has_user_event,archived,cli_version,first_user_message,memory_mode,created_at_ms,updated_at_ms,thread_source,preview) values('old-0001',$(Quote-CHRSql $oldPath),1,1,'vscode','codex_local_access',$(Quote-CHRSql $dbCwd),'old title','{}','on-request',0,1,0,'0.old','old title','enabled',1000,1000,'user','old title');" | Out-Null
Set-Content -LiteralPath $sessionIndex -Value "" -Encoding UTF8
([pscustomobject]@{
    "project-order" = @()
    "projectless-thread-ids" = @()
    "thread-workspace-root-hints" = [pscustomobject]@{}
    "electron-saved-workspace-roots" = @()
} | ConvertTo-Json -Depth 10 -Compress) | Set-Content -LiteralPath $globalState -Encoding UTF8

$template = Get-CHRTemplate -Database $db
Assert-True ($template.ModelProvider -eq "openai") "Template provider should be detected"
$rows = @(Get-CHRThreadRows -Database $db -ProjectDbCwd $dbCwd -OldOnly)
Assert-True ($rows.Count -eq 1) "Old row should be listed"
$backup = New-CHRBackup -Database $db -JsonlPaths (Get-CHRRolloutPaths -Database $db -Rows $rows) -BackupRoot (Join-Path $OutputRoot "backups") -Operation "restore" -CodexHome $codexHome -ProjectRoot $jsonCwd -Rows $rows
Assert-True (Test-Path (Join-Path $backup "manifest.json")) "Backup manifest should exist"
Repair-CHRThreads -Database $db -Rows $rows -ProjectDbCwd $dbCwd -ProjectJsonCwd $jsonCwd -Template $template | Out-Null
$provider = (Invoke-CHRSqlite -Database $db -Sql "select model_provider from threads where id='old-0001';").Trim()
Assert-True ($provider -eq "openai") "Provider should be repaired to current provider"
$sync = Sync-CHRSidebarState -Database $db -CodexHome $codexHome -CurrentModelProvider $template.ModelProvider
Assert-True ($sync.ThreadCount -eq 2) "Sidebar sync should index template and restored thread"
Assert-True ((Get-Content -LiteralPath $sessionIndex -Raw -Encoding UTF8) -match "old-0001") "Session index should include restored thread"
$state = Get-Content -LiteralPath $globalState -Raw -Encoding UTF8 | ConvertFrom-Json
$oldHint = $state."thread-workspace-root-hints".PSObject.Properties["old-0001"].Value
Assert-True ($oldHint -eq $project) "Global state should include restored thread hint"
$tools = (Invoke-CHRSqlite -Database $db -Sql "select count(*) from thread_dynamic_tools where thread_id='old-0001';").Trim()
Assert-True ([int]$tools -eq 1) "Dynamic tools should be copied"
Restore-CHRBackup -BackupPath $backup | Out-Null
$providerAfterRollback = (Invoke-CHRSqlite -Database $db -Sql "select model_provider from threads where id='old-0001';").Trim()
Assert-True ($providerAfterRollback -eq "codex_local_access") "Rollback should restore provider"

$sourceDir = Join-Path $OutputRoot "external\sessions\2026\05\24"
New-Item -ItemType Directory -Path $sourceDir -Force | Out-Null
$newPath = Join-Path $sourceDir "rollout-new-0001.jsonl"
Write-JsonLine $newPath ([pscustomobject]@{
    timestamp = "2026-05-24T00:02:00.000Z"
    type = "session_meta"
    payload = [pscustomobject]@{ id = "new-0001"; timestamp = "2026-05-24T00:02:00.000Z"; cwd = $jsonCwd; source = "vscode"; model_provider = "openai" }
})
Write-JsonLine $newPath ([pscustomobject]@{
    type = "response_item"
    payload = [pscustomobject]@{ role = "user"; content = @([pscustomobject]@{ text = "hello imported" }) }
})
$scan = Test-CHRImportSessions -Database $db -SessionsDir (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $sourceDir)))
Assert-True ($scan.Importable -eq 1) "One importable session expected"
$import = Import-CHRJsonlSessions -Database $db -CodexHome $codexHome -SessionsDir (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $sourceDir))) -ProjectDbCwd $dbCwd -ProjectJsonCwd $jsonCwd -Template $template
Assert-True (@($import.Imported).Count -eq 1) "One session should be imported"

Write-Host "Smoke tests passed."
