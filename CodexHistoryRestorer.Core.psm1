$script:DefaultBackupRoot = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "CodexHistoryRestorerBackups"

function Write-CHRInfo {
    param([string] $Message)
    Write-Host "[codex-history-restorer] $Message"
}

function Quote-CHRSql {
    param([AllowNull()][string] $Value)
    if ($null -eq $Value) { return "''" }
    return "'" + ($Value -replace "'", "''") + "'"
}

function Get-CHRDefaultCodexHome {
    if ($env:CODEX_HOME) { return $env:CODEX_HOME }
    return (Join-Path $env:USERPROFILE ".codex")
}

function Get-CHRDefaultBackupRoot {
    return $script:DefaultBackupRoot
}

function Get-CHRSqlitePath {
    $local = Join-Path $PSScriptRoot "tools\sqlite3.exe"
    if (Test-Path -LiteralPath $local) { return $local }
    $cmd = Get-Command sqlite3 -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    throw "sqlite3.exe was not found. Place sqlite3.exe in tools\ or install SQLite and add sqlite3 to PATH."
}

function Invoke-CHRSqlite {
    param(
        [Parameter(Mandatory = $true)] [string] $Database,
        [Parameter(Mandatory = $true)] [string] $Sql,
        [string] $Separator = ""
    )
    $sqlite = Get-CHRSqlitePath
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $sqlite
    $psi.UseShellExecute = $false
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8
    $escapedDatabase = $Database.Replace('"', '\"')
    if ($Separator) {
        $escapedSeparator = $Separator.Replace('"', '\"')
        $psi.Arguments = "-separator `"$escapedSeparator`" `"$escapedDatabase`""
    } else {
        $psi.Arguments = "`"$escapedDatabase`""
    }
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    [void]$process.Start()
    $process.StandardInput.WriteLine($Sql)
    $process.StandardInput.Close()
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    if ($process.ExitCode -ne 0) {
        if ([string]::IsNullOrWhiteSpace($stderr)) { $stderr = "sqlite3 failed with exit code $($process.ExitCode)" }
        throw $stderr.Trim()
    }
    if ([string]::IsNullOrEmpty($stdout)) { return @() }
    return @($stdout -split "\r?\n" | Where-Object { $_ -ne "" })
}

function Ensure-CHRProperty {
    param(
        [Parameter(Mandatory = $true)] $Object,
        [Parameter(Mandatory = $true)] [string] $Name,
        [Parameter(Mandatory = $true)] $Value
    )
    if ($Object.PSObject.Properties.Name -contains $Name) {
        $Object.$Name = $Value
    } else {
        $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    }
}

function ConvertTo-CHRDbCwd {
    param([string] $Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return "" }
    $full = [System.IO.Path]::GetFullPath($Path)
    if ($full.StartsWith("\\?\")) { return $full }
    return "\\?\$full"
}

function ConvertTo-CHRJsonCwd {
    param([string] $Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return "" }
    return [System.IO.Path]::GetFullPath($Path)
}

function ConvertTo-CHRUnixMs {
    param([string] $Timestamp)
    try { return [DateTimeOffset]::Parse($Timestamp).ToUnixTimeMilliseconds() }
    catch { return [DateTimeOffset]::Now.ToUnixTimeMilliseconds() }
}

function Get-CHRShortTitle {
    param([string] $Title, [int] $MaxLength = 90)
    $clean = ($Title -replace "\s+", " ").Trim()
    if ($clean.Length -gt $MaxLength) { return $clean.Substring(0, $MaxLength) + "..." }
    if ($clean) { return $clean }
    return "(untitled)"
}

function Get-CHRSessionMeta {
    param([string] $Path)
    $line = Get-Content -LiteralPath $Path -TotalCount 1 -Encoding UTF8
    if (-not $line) { throw "Empty JSONL file: $Path" }
    $json = $line | ConvertFrom-Json
    if ($json.type -ne "session_meta") { throw "First JSONL row is not session_meta: $Path" }
    return $json
}

function Get-CHRFirstUserText {
    param([string] $Path)
    $lines = Get-Content -LiteralPath $Path -TotalCount 500 -Encoding UTF8
    foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        try { $j = $line | ConvertFrom-Json } catch { continue }
        if ($j.type -eq "response_item" -and $j.payload.role -eq "user") {
            foreach ($item in @($j.payload.content)) {
                if ($item.text) { return ($item.text -replace "\s+", " ").Trim() }
                if ($item.content) { return ($item.content -replace "\s+", " ").Trim() }
            }
        }
        if ($j.type -eq "event_msg" -and $j.payload.type -eq "user_message" -and $j.payload.message) {
            return ($j.payload.message -replace "\s+", " ").Trim()
        }
        if ($j.type -eq "event_msg" -and $j.payload.message -and $j.payload.type -match "user") {
            return ($j.payload.message -replace "\s+", " ").Trim()
        }
        if ($j.payload.role -eq "user" -and $j.payload.content) {
            return (($j.payload.content | ConvertTo-Json -Compress) -replace "\s+", " ").Trim()
        }
    }
    return ""
}

function Get-CHRDesktopProcesses {
    $processes = @()
    try {
        $processes = @(Get-CimInstance Win32_Process -ErrorAction Stop | Where-Object {
            ($_.ExecutablePath -and $_.ExecutablePath -match "OpenAI\\Codex|OpenAI\.Codex|\\Codex\\")
        } | Select-Object ProcessId, Name, ExecutablePath)
    } catch {
        $processes = @()
    }
    return $processes
}

function Test-CHREnvironment {
    param([string] $CodexHome = (Get-CHRDefaultCodexHome))
    $dbPath = Join-Path $CodexHome "state_5.sqlite"
    $sqlitePath = ""
    $sqliteOk = $false
    $template = $null
    $templateOk = $false
    $errors = New-Object System.Collections.Generic.List[string]
    try {
        $sqlitePath = Get-CHRSqlitePath
        $sqliteOk = $true
    } catch { [void]$errors.Add($_.Exception.Message) }
    if (-not (Test-Path -LiteralPath $CodexHome)) { [void]$errors.Add("Codex home not found: $CodexHome") }
    if (-not (Test-Path -LiteralPath $dbPath)) { [void]$errors.Add("Codex database not found: $dbPath") }
    if ($sqliteOk -and (Test-Path -LiteralPath $dbPath)) {
        try {
            $template = Get-CHRTemplate -Database $dbPath -RequestedThreadId ""
            $templateOk = $true
        } catch { [void]$errors.Add($_.Exception.Message) }
    }
    $desktopProcesses = @()
    return [pscustomobject]@{
        CodexHome = $CodexHome
        Database = $dbPath
        SqlitePath = $sqlitePath
        SqliteOk = $sqliteOk
        DatabaseOk = (Test-Path -LiteralPath $dbPath)
        TemplateOk = $templateOk
        TemplateThreadId = if ($template) { $template.Id } else { "" }
        DesktopProcesses = $desktopProcesses
        DesktopRunning = $false
        Errors = @($errors)
        Ok = ($errors.Count -eq 0)
    }
}

function Get-CHRTemplate {
    param([Parameter(Mandatory = $true)] [string] $Database, [string] $RequestedThreadId = "")
    $id = $RequestedThreadId
    if (-not $id) {
        $sql = @"
select t.id
from threads t
join thread_dynamic_tools d on d.thread_id = t.id
where coalesce(t.thread_source, '') = 'user'
group by t.id
having count(d.thread_id) > 0
order by t.updated_at_ms desc, t.id desc
limit 1;
"@
        $id = (Invoke-CHRSqlite -Database $Database -Sql $sql | Select-Object -First 1).Trim()
    }
    if (-not $id) { throw "No visible Codex Desktop template thread was found. Create one normal Codex Desktop chat first, or pass -TemplateThreadId." }
    $path = (Invoke-CHRSqlite -Database $Database -Sql "select rollout_path from threads where id=$(Quote-CHRSql $id);").Trim()
    if (-not (Test-Path -LiteralPath $path)) { throw "Template rollout file not found: $path" }
    $meta = Get-CHRSessionMeta -Path $path
    $cli = $meta.payload.cli_version
    if (-not $cli) { $cli = (Invoke-CHRSqlite -Database $Database -Sql "select cli_version from threads where id=$(Quote-CHRSql $id);").Trim() }
    if (-not $cli) { $cli = "0.133.0-alpha.1" }
    $provider = (Invoke-CHRSqlite -Database $Database -Sql "select coalesce(model_provider,'') from threads where id=$(Quote-CHRSql $id);").Trim()
    if (-not $provider) { $provider = $meta.payload.model_provider }
    if (-not $provider) { $provider = "openai" }
    return [pscustomobject]@{ Id = $id; Path = $path; CliVersion = $cli; ModelProvider = $provider; DynamicTools = @($meta.payload.dynamic_tools) }
}

function Get-CHRProjects {
    param([Parameter(Mandatory = $true)] [string] $Database)
    $sql = @"
select cwd, count(*) as count
from threads
where archived=0 and has_user_event=1
group by cwd
order by max(updated_at_ms) desc;
"@
    $raw = Invoke-CHRSqlite -Database $Database -Sql $sql -Separator "`t"
    $rows = @()
    foreach ($line in $raw) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $parts = $line -split "`t", 2
        $cwd = $parts[0]
        $display = $cwd -replace "^\\\\\?\\", ""
        $rows += [pscustomobject]@{ Cwd = $cwd; Path = $display; Count = [int]$parts[1] }
    }
    return $rows
}

function Find-CHRSources {
    param([string] $CodexHome = (Get-CHRDefaultCodexHome), [string[]] $ExtraRoots = @())
    $candidateRoots = New-Object System.Collections.Generic.List[string]
    foreach ($path in @(
        (Join-Path $CodexHome "sessions"),
        (Join-Path $CodexHome "archived_sessions"),
        (Join-Path $env:USERPROFILE ".codex\sessions"),
        (Join-Path $env:USERPROFILE ".codex\archived_sessions"),
        (Join-Path $env:APPDATA "Code\User\globalStorage"),
        (Join-Path $env:APPDATA "Cursor\User\globalStorage"),
        (Join-Path $env:USERPROFILE ".vscode"),
        (Join-Path $env:USERPROFILE "Documents"),
        (Join-Path $env:USERPROFILE "Downloads")
    )) {
        if ($path -and -not $candidateRoots.Contains($path)) { [void]$candidateRoots.Add($path) }
    }
    foreach ($path in $ExtraRoots) {
        if ($path -and -not $candidateRoots.Contains($path)) { [void]$candidateRoots.Add($path) }
    }
    $sources = @{}
    foreach ($root in $candidateRoots) {
        if (-not (Test-Path -LiteralPath $root)) { continue }
        try { $files = @(Get-ChildItem -LiteralPath $root -Filter "rollout-*.jsonl" -Recurse -File -ErrorAction SilentlyContinue) }
        catch { continue }
        if ($files.Count -eq 0) { continue }
        foreach ($group in ($files | Group-Object DirectoryName)) {
            $dir = $group.Name
            if (-not $dir) { continue }
            $sessionRoot = $dir
            $parent = Split-Path -Parent $dir
            $grand = if ($parent) { Split-Path -Parent $parent } else { "" }
            if ((Split-Path -Leaf $grand) -match "^\d{4}$" -and (Split-Path -Leaf $parent) -match "^\d{2}$" -and (Split-Path -Leaf $dir) -match "^\d{2}$") {
                $sessionRoot = Split-Path -Parent $grand
            }
            $full = [System.IO.Path]::GetFullPath($sessionRoot)
            $key = $full.ToLowerInvariant()
            if (-not $sources.ContainsKey($key)) {
                $allFiles = @(Get-ChildItem -LiteralPath $full -Filter "rollout-*.jsonl" -Recurse -File -ErrorAction SilentlyContinue)
                $lastWrite = if ($allFiles.Count -gt 0) { ($allFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime } else { (Get-Item -LiteralPath $full).LastWriteTime }
                $kind = "External"
                if ($full.TrimEnd("\") -ieq (Join-Path $CodexHome "sessions").TrimEnd("\")) { $kind = "Current Codex" }
                elseif ($full.TrimEnd("\") -ieq (Join-Path $CodexHome "archived_sessions").TrimEnd("\")) { $kind = "Archived" }
                $sources[$key] = [pscustomobject]@{
                    Path = $full
                    JsonlCount = $allFiles.Count
                    LastWriteTime = $lastWrite
                    SourceKind = $kind
                    IsCurrentCodex = ($kind -eq "Current Codex")
                }
            }
        }
    }
    return @($sources.Values | Sort-Object IsCurrentCodex, LastWriteTime -Descending)
}

function Get-CHRThreadRows {
    param([Parameter(Mandatory = $true)] [string] $Database, [string] $ProjectDbCwd = "", [switch] $OldOnly)
    $where = "t.archived=0 and t.has_user_event=1"
    if ($ProjectDbCwd) { $where += " and t.cwd=$(Quote-CHRSql $ProjectDbCwd)" }
    if ($OldOnly) { $where += " and (coalesce(t.thread_source,'') <> 'user' or coalesce(d.tool_count,0) <= 0)" }
    $sql = @"
select
  id,
  replace(replace(replace(title, char(13), ' '), char(10), ' '), char(9), ' ') as title,
  cwd,
  coalesce(thread_source, '') as thread_source,
  model_provider,
  coalesce(cli_version, '') as cli_version,
  updated_at_ms,
  coalesce(d.tool_count, 0) as tool_count
from threads t
left join (
  select thread_id, count(*) as tool_count
  from thread_dynamic_tools
  group by thread_id
) d on d.thread_id = t.id
where $where
order by t.updated_at_ms desc, t.id desc;
"@
    $raw = Invoke-CHRSqlite -Database $Database -Sql $sql -Separator "`t"
    $rows = @()
    $number = 1
    foreach ($line in $raw) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $parts = $line -split "`t", 8
        if ($parts.Count -lt 8) { continue }
        $status = if ($parts[3] -eq "user" -and ([int]$parts[7]) -gt 0) { "desktop" } else { "old" }
        $rows += [pscustomobject]@{
            Number = $number
            Id = $parts[0]
            Title = $parts[1]
            Cwd = $parts[2]
            ThreadSource = $parts[3]
            ModelProvider = $parts[4]
            CliVersion = $parts[5]
            UpdatedAtMs = [int64]$parts[6]
            UpdatedAt = [DateTimeOffset]::FromUnixTimeMilliseconds([int64]$parts[6]).LocalDateTime
            Status = $status
            ToolCount = [int]$parts[7]
        }
        $number++
    }
    return $rows
}

function Test-CHRImportSessions {
    param([Parameter(Mandatory = $true)] [string] $Database, [Parameter(Mandatory = $true)] [string] $SessionsDir)
    if (-not (Test-Path -LiteralPath $SessionsDir)) { throw "Source sessions directory not found: $SessionsDir" }
    $files = @(Get-ChildItem -LiteralPath $SessionsDir -Filter "rollout-*.jsonl" -Recurse -File -ErrorAction SilentlyContinue)
    $items = @()
    $existing = 0
    $invalid = 0
    foreach ($file in $files) {
        $id = ""
        $title = ""
        $reason = ""
        $status = "Importable"
        try {
            $meta = Get-CHRSessionMeta -Path $file.FullName
            $id = $meta.payload.id
            if (-not $id) { throw "Missing session id" }
            $count = (Invoke-CHRSqlite -Database $Database -Sql "select count(*) from threads where id=$(Quote-CHRSql $id);").Trim()
            if ([int]$count -gt 0) {
                $status = "Existing"
                $existing++
            }
            $title = Get-CHRFirstUserText -Path $file.FullName
            if (-not $title) { $title = "$($file.LastWriteTime.ToString('yyyy-MM-dd HH:mm')) $id" }
        } catch {
            $status = "Invalid"
            $reason = $_.Exception.Message
            $invalid++
        }
        $items += [pscustomobject]@{ Path = $file.FullName; Id = $id; Title = $title; Status = $status; Reason = $reason }
    }
    $importable = @($items | Where-Object { $_.Status -eq "Importable" }).Count
    return [pscustomobject]@{ Scanned = $files.Count; Existing = $existing; Importable = $importable; Invalid = $invalid; Items = @($items) }
}

function Get-CHRSafeDestination {
    param([Parameter(Mandatory = $true)] [string] $Directory, [Parameter(Mandatory = $true)] [string] $FileName, [Parameter(Mandatory = $true)] [string] $ThreadId)
    $dest = Join-Path $Directory $FileName
    if (-not (Test-Path -LiteralPath $dest)) { return $dest }
    $stem = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
    $ext = [System.IO.Path]::GetExtension($FileName)
    $suffix = if ($ThreadId.Length -gt 8) { $ThreadId.Substring(0, 8) } else { $ThreadId }
    $i = 1
    do {
        $dest = Join-Path $Directory ("$stem-$suffix-$i$ext")
        $i++
    } while (Test-Path -LiteralPath $dest)
    return $dest
}

function Write-CHRAllLinesAtomic {
    param(
        [Parameter(Mandatory = $true)] [string] $Path,
        [Parameter(Mandatory = $true)] [string[]] $Lines
    )
    $tmp = "$Path.chr-tmp-$([guid]::NewGuid().ToString('N'))"
    [System.IO.File]::WriteAllLines($tmp, $Lines, [System.Text.UTF8Encoding]::new($false))
    try {
        if (Test-Path -LiteralPath $Path) {
            try {
                [System.IO.File]::Replace($tmp, $Path, $null)
            } catch {
                Move-Item -LiteralPath $tmp -Destination $Path -Force
            }
        } else {
            Move-Item -LiteralPath $tmp -Destination $Path -Force
        }
    } finally {
        if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }
    }
}

function Import-CHRJsonlSessions {
    param(
        [Parameter(Mandatory = $true)] [string] $Database,
        [Parameter(Mandatory = $true)] [string] $CodexHome,
        [Parameter(Mandatory = $true)] [string] $SessionsDir,
        [string] $ProjectDbCwd = "",
        [string] $ProjectJsonCwd = "",
        [Parameter(Mandatory = $true)] $Template
    )
    $scan = Test-CHRImportSessions -Database $Database -SessionsDir $SessionsDir
    $imported = @()
    $insertSql = New-Object System.Collections.Generic.List[string]
    foreach ($item in @($scan.Items | Where-Object { $_.Status -eq "Importable" })) {
        $file = Get-Item -LiteralPath $item.Path
        $meta = Get-CHRSessionMeta -Path $file.FullName
        $id = $meta.payload.id
        $ms = ConvertTo-CHRUnixMs -Timestamp $meta.payload.timestamp
        $sec = [Math]::Floor($ms / 1000)
        $jsonCwd = if ($ProjectJsonCwd) { $ProjectJsonCwd } else { $meta.payload.cwd }
        $dbCwd = if ($ProjectDbCwd) { $ProjectDbCwd } else { ConvertTo-CHRDbCwd $jsonCwd }
        $title = $item.Title
        if (-not $title) { $title = "$($file.LastWriteTime.ToString('yyyy-MM-dd HH:mm')) $id" }
        $destDir = Join-Path $CodexHome ("sessions\{0:yyyy}\{0:MM}\{0:dd}" -f ([DateTimeOffset]::FromUnixTimeMilliseconds($ms).LocalDateTime))
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        $dest = Get-CHRSafeDestination -Directory $destDir -FileName $file.Name -ThreadId $id
        Copy-Item -LiteralPath $file.FullName -Destination $dest -Force
        $insert = @"
insert into threads (
  id, rollout_path, created_at, updated_at, source, model_provider, cwd, title,
  sandbox_policy, approval_mode, tokens_used, has_user_event, archived,
  cli_version, first_user_message, memory_mode, model, reasoning_effort,
  created_at_ms, updated_at_ms, thread_source, preview
) values (
  $(Quote-CHRSql $id),
  $(Quote-CHRSql $dest),
  $sec,
  $sec,
  'vscode',
  'codex_local_access',
  $(Quote-CHRSql $dbCwd),
  $(Quote-CHRSql $title),
  $(Quote-CHRSql '{"type":"workspace-write","network_access":false,"exclude_tmpdir_env_var":false,"exclude_slash_tmp":false}'),
  'on-request',
  0,
  1,
  0,
  $(Quote-CHRSql $Template.CliVersion),
  $(Quote-CHRSql $title),
  'enabled',
  '',
  '',
  $ms,
  $ms,
  'user',
  $(Quote-CHRSql $title)
);
"@
        [void]$insertSql.Add($insert)
        $imported += [pscustomobject]@{ Id = $id; Path = $dest; Title = $title }
    }
    if ($insertSql.Count -gt 0) {
        try {
            Invoke-CHRSqlite -Database $Database -Sql (".bail on`nbegin immediate;`n" + (($insertSql.ToArray()) -join "`n") + "`ncommit;") | Out-Null
        } catch {
            foreach ($item in $imported) {
                if (Test-Path -LiteralPath $item.Path) { Remove-Item -LiteralPath $item.Path -Force -ErrorAction SilentlyContinue }
            }
            throw
        }
    }
    return [pscustomobject]@{ Imported = @($imported); Skipped = @($scan.Items | Where-Object { $_.Status -ne "Importable" }); Scanned = $scan.Scanned; Existing = $scan.Existing; Invalid = $scan.Invalid }
}

function New-CHRBackup {
    param(
        [Parameter(Mandatory = $true)] [string] $Database,
        [string[]] $JsonlPaths = @(),
        [string] $BackupRoot = (Get-CHRDefaultBackupRoot),
        [string] $Operation = "restore",
        [string] $CodexHome = (Split-Path -Parent $Database),
        [string] $ProjectRoot = "",
        [object[]] $Rows = @()
    )
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $dir = Join-Path $BackupRoot "codex-history-restore-backup-$stamp"
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $files = @()
    foreach ($dbFile in @($Database, "$Database-wal", "$Database-shm")) {
        if (Test-Path -LiteralPath $dbFile) {
            $name = Split-Path -Leaf $dbFile
            Copy-Item -LiteralPath $dbFile -Destination (Join-Path $dir $name) -Force
            $files += [pscustomobject]@{ Kind = "database"; OriginalPath = $dbFile; BackupFile = $name }
        }
    }
    foreach ($path in @($JsonlPaths | Sort-Object -Unique)) {
        if (Test-Path -LiteralPath $path) {
            $name = Split-Path -Leaf $path
            $target = Join-Path $dir $name
            if (Test-Path -LiteralPath $target) {
                $name = ([System.IO.Path]::GetFileNameWithoutExtension($name) + "-" + ([guid]::NewGuid().ToString("N").Substring(0, 8)) + [System.IO.Path]::GetExtension($name))
                $target = Join-Path $dir $name
            }
            Copy-Item -LiteralPath $path -Destination $target -Force
            $files += [pscustomobject]@{ Kind = "jsonl"; OriginalPath = $path; BackupFile = $name }
        }
    }
    $manifest = [pscustomobject]@{
        Tool = "Codex History Restorer"
        Version = "0.2.0"
        CreatedAt = (Get-Date).ToString("o")
        Operation = $Operation
        CodexHome = $CodexHome
        ProjectRoot = $ProjectRoot
        Threads = @($Rows | ForEach-Object { [pscustomobject]@{ Id = $_.Id; Title = $_.Title; Cwd = $_.Cwd } })
        Files = $files
    }
    $manifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $dir "manifest.json") -Encoding UTF8
    return $dir
}

function Get-CHRBackups {
    param([string] $BackupRoot = (Get-CHRDefaultBackupRoot))
    if (-not (Test-Path -LiteralPath $BackupRoot)) { return @() }
    $dirs = @(Get-ChildItem -LiteralPath $BackupRoot -Directory -Filter "codex-history-restore-backup-*" -ErrorAction SilentlyContinue)
    $rows = @()
    foreach ($dir in $dirs) {
        $manifestPath = Join-Path $dir.FullName "manifest.json"
        $manifest = $null
        if (Test-Path -LiteralPath $manifestPath) {
            try { $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json } catch { $manifest = $null }
        }
        $rows += [pscustomobject]@{
            Path = $dir.FullName
            Name = $dir.Name
            CreatedAt = if ($manifest) { [DateTimeOffset]::Parse($manifest.CreatedAt).LocalDateTime } else { $dir.CreationTime }
            Operation = if ($manifest) { $manifest.Operation } else { "unknown" }
            ThreadCount = if ($manifest) { @($manifest.Threads).Count } else { 0 }
            HasManifest = ($null -ne $manifest)
        }
    }
    return @($rows | Sort-Object CreatedAt -Descending)
}

function Restore-CHRBackup {
    param([Parameter(Mandatory = $true)] [string] $BackupPath)
    $manifestPath = Join-Path $BackupPath "manifest.json"
    if (-not (Test-Path -LiteralPath $manifestPath)) { throw "Backup manifest not found: $manifestPath" }
    $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($file in @($manifest.Files)) {
        $source = Join-Path $BackupPath $file.BackupFile
        if (-not (Test-Path -LiteralPath $source)) { throw "Backup file missing: $source" }
    }
    foreach ($file in @($manifest.Files)) {
        $source = Join-Path $BackupPath $file.BackupFile
        $parent = Split-Path -Parent $file.OriginalPath
        if ($parent -and -not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        Copy-Item -LiteralPath $source -Destination $file.OriginalPath -Force
    }
    return [pscustomobject]@{ Restored = @($manifest.Files).Count; BackupPath = $BackupPath; Operation = $manifest.Operation }
}

function Repair-CHRThreads {
    param(
        [Parameter(Mandatory = $true)] [string] $Database,
        [Parameter(Mandatory = $true)] [object[]] $Rows,
        [string] $ProjectDbCwd = "",
        [string] $ProjectJsonCwd = "",
        [Parameter(Mandatory = $true)] $Template,
        [switch] $NoTouch
    )
    $baseMs = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
    $offset = 0
    $changed = @()
    $dbStatements = New-Object System.Collections.Generic.List[string]
    $jsonUpdates = @()
    foreach ($row in $Rows) {
        $id = $row.Id
        $rollout = (Invoke-CHRSqlite -Database $Database -Sql "select rollout_path from threads where id=$(Quote-CHRSql $id);").Trim()
        if (-not (Test-Path -LiteralPath $rollout)) { throw "Rollout file not found for ${id}: $rollout" }
        $provider = if ($Template.ModelProvider) { $Template.ModelProvider } else { "openai" }
        $updates = @("source='vscode'", "thread_source='user'", "model_provider=$(Quote-CHRSql $provider)", "cli_version=$(Quote-CHRSql $Template.CliVersion)", "has_user_event=1", "archived=0")
        if ($ProjectDbCwd) { $updates += "cwd=$(Quote-CHRSql $ProjectDbCwd)" }
        if (-not $NoTouch) {
            $ms = $baseMs + $offset
            $sec = [Math]::Floor($ms / 1000)
            $updates += "updated_at=$sec"
            $updates += "updated_at_ms=$ms"
            $offset++
        }
        [void]$dbStatements.Add("update threads set $($updates -join ', ') where id=$(Quote-CHRSql $id);")
        [void]$dbStatements.Add("delete from thread_dynamic_tools where thread_id=$(Quote-CHRSql $id);")
        [void]$dbStatements.Add("insert into thread_dynamic_tools(thread_id, position, name, description, input_schema, defer_loading, namespace) select $(Quote-CHRSql $id), position, name, description, input_schema, defer_loading, namespace from thread_dynamic_tools where thread_id=$(Quote-CHRSql $Template.Id);")
        $lines = [System.IO.File]::ReadAllLines($rollout, [System.Text.Encoding]::UTF8)
        $meta = $lines[0] | ConvertFrom-Json
        Ensure-CHRProperty -Object $meta.payload -Name "source" -Value "vscode"
        Ensure-CHRProperty -Object $meta.payload -Name "thread_source" -Value "user"
        Ensure-CHRProperty -Object $meta.payload -Name "model_provider" -Value $provider
        Ensure-CHRProperty -Object $meta.payload -Name "cli_version" -Value $Template.CliVersion
        Ensure-CHRProperty -Object $meta.payload -Name "dynamic_tools" -Value @($Template.DynamicTools)
        if ($ProjectJsonCwd) { Ensure-CHRProperty -Object $meta.payload -Name "cwd" -Value $ProjectJsonCwd }
        $lines[0] = $meta | ConvertTo-Json -Depth 100 -Compress
        $jsonUpdates += [pscustomobject]@{ Path = $rollout; Lines = [string[]]$lines }
        $changed += [pscustomobject]@{ Id = $id; RolloutPath = $rollout; Title = $row.Title }
    }
    if ($dbStatements.Count -gt 0) {
        Invoke-CHRSqlite -Database $Database -Sql (".bail on`nbegin immediate;`n" + (($dbStatements.ToArray()) -join "`n") + "`ncommit;") | Out-Null
    }
    foreach ($update in $jsonUpdates) {
        Write-CHRAllLinesAtomic -Path $update.Path -Lines $update.Lines
    }
    return $changed
}

function Get-CHRRolloutPaths {
    param([Parameter(Mandatory = $true)] [string] $Database, [Parameter(Mandatory = $true)] [object[]] $Rows)
    $paths = @()
    foreach ($row in $Rows) {
        $path = (Invoke-CHRSqlite -Database $Database -Sql "select rollout_path from threads where id=$(Quote-CHRSql $row.Id);").Trim()
        if ($path) { $paths += $path }
    }
    return @($paths)
}

Export-ModuleMember -Function *-CHR*
