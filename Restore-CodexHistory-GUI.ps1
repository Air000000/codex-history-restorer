$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "CodexHistoryRestorer.Core.psm1") -Force -DisableNameChecking

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

$script:Rows = @()
$script:LastEnvironment = $null
$script:Language = if ((Get-Culture).TwoLetterISOLanguageName -eq "zh") { "zh" } else { "en" }
$script:ApplyingLanguage = $false
$script:IsBusy = $false

$script:Strings = @{
    en = @{
        AppTitle = "Codex History Restorer"
        HeroTitle = "Restore Codex chats"
        HeroSubtitle = "Find recoverable chats, select what to repair, then restore. Nothing is changed until import or final restore."
        NextChooseProject = "Next: click Find recoverable records. The tool will also look for chats in backups and other Codex folders."
        NextEnvIssue = "Next: use More tools > Re-check environment. If sqlite3 is missing, put sqlite3.exe in the tools folder or install it in PATH."
        NextLoad = "Next: click Find recoverable records. External sources are scanned first and imported only after you confirm."
        NextSelect = "Next: click Select repairable, or tick rows manually. Repairable rows are usually the ones to restore."
        NextPreview = "Next: click Restore selected. A backup will be created before anything is changed."
        PreviewComplete = "Preview complete. If the selected rows are correct, click Restore selected."
        PreviewDialogTitle = "Restore preview"
        PreviewDialogBody = "No files were changed.`n`nTemplate: {0}`nSelected: {1}`nProject handling: {2}`n`nThreads:`n{3}"
        PreviewMore = "... and {0} more"
        RestoreComplete = "Restore complete. Return to Codex Desktop, switch projects or restart Codex, then check the restored chats."
        ImportComplete = "Import complete. Imported rows are now loaded; select and restore the repairable rows next."
        EnvChecking = "Environment: checking..."
        EnvNotChecked = "Environment: not checked"
        EnvReady = "Environment: ready"
        EnvNeedsAttention = "Environment: needs attention"
        ProjectNotSelected = "Project: original projects"
        ProjectPrefix = "Move to project: {0}"
        RecordsNotLoaded = "Records: not loaded"
        RecordsLoaded = "Records: {0} loaded, {1} need repair"
        SelectedCount = "Selected: {0}"
        RestoreInto = "Project override"
        ChooseProject = "Choose project"
        BrowseFolder = "Browse folder"
        SimpleHelp = "Start with Find recoverable records. If chats are found outside current Codex, you can choose which sources to import."
        LoadRecords = "Find recoverable records"
        SelectHidden = "Select repairable"
        Preview = "Preview"
        RestoreSelected = "Restore selected"
        MoreTools = "More tools..."
        CodexHome = "Codex home"
        ReCheck = "Re-check"
        ImportSource = "Import source"
        Browse = "Browse"
        FindSources = "Find sources"
        BackupFolder = "Backup folder"
        Rollback = "Rollback"
        TemplateThread = "Template thread"
        HiddenOnly = "Repairable only"
        DoNotBump = "Do not bump"
        Search = "Search"
        All = "All"
        Hidden = "Needs repair"
        Visible = "Ready"
        Status = "Status"
        Title = "Title"
        ThreadId = "Thread Id"
        Updated = "Updated"
        Project = "Project"
        Threads = "Threads"
        Created = "Created"
        Operation = "Operation"
        Manifest = "Manifest"
        Path = "Path"
        LastWrite = "Last Write"
        Kind = "Kind"
        Language = "Language"
        ShowAdvanced = "Settings and recovery..."
        HideAdvanced = "Hide settings"
        ClearSelection = "Clear selection"
        ShowLog = "Show log"
        HideLog = "Hide log"
        ImportSessions = "Import typed source..."
        ScanOtherSources = "Find chats in other locations..."
        ImportFoundSources = "Import selected sources"
        ImportFoundTitle = "Import Found Sources"
        ImportFoundHelp = "Chats in these folders are not in the current Codex database yet. Check the sources you want to import."
        SourcePreview = "Preview"
        EmptyStateTitle = "No records loaded yet"
        EmptyStateBody = "Click Find recoverable records to scan current Codex, backups, and other local Codex folders."
        EmptyFilterTitle = "No rows match this filter"
        EmptyFilterBody = "Try All, clear Search, or click Find recoverable records again."
        TemplateHelp = "No visible Codex template chat was found. Create one normal chat in Codex Desktop, then click Re-check environment."
        BackupsRollback = "Backups / rollback"
        ReCheckEnvironment = "Re-check environment"
        UseSelected = "Use Selected"
        Cancel = "Cancel"
        Close = "Close"
        RollbackSelected = "Rollback Selected"
        ChooseProjectRoot = "Choose Project Root"
        ThreadDetails = "Thread Details"
        ConfirmRestore = "Confirm restore"
        ConfirmImport = "Confirm import"
        CodexRunningTitle = "Codex is running"
        ImportSessionsTitle = "Import Sessions"
        FindSourcesTitle = "Find Sources"
        ChooseSourceTitle = "Choose Source Sessions Folder"
        ErrorPrefix = "ERROR: {0}"
        EnvironmentOk = "Environment OK."
        EnvironmentIssues = "Environment has issues."
        CodexHomeLog = "Codex home: {0}"
        DatabaseLog = "Database: {0}"
        TemplateLog = "Template thread: {0}"
        DesktopRunningWarning = "Warning: Codex Desktop appears to be running. Close Codex before restore, import, or rollback."
        DbNotFound = "Codex database not found: {0}"
        LoadedThreads = "Loaded {0} thread(s)."
        ShowingThreads = "Showing {0} of {1} thread(s)."
        SelectedHiddenRows = "Selected all repairable rows."
        SelectionCleared = "Selection cleared."
        SelectAtLeastOne = "Select at least one thread first."
        DryRunNoChanges = "Dry run. No files will be changed."
        WouldRestore = "Would restore {0} thread(s):"
        RestoreCancelled = "Restore cancelled."
        BackupCreated = "Backup created: {0}"
        RestoredThreads = "Restored {0} thread(s)."
        ChooseExternalFirst = "Choose an external sessions folder first."
        ImportScan = "Import scan: scanned={0} importable={1} existing={2} invalid={3}"
        ImportCancelled = "Import cancelled."
        DatabaseBackupCreated = "Database backup created: {0}"
        ImportResult = "Scanned {0} JSONL file(s). Imported {1}, existing={2}, invalid={3}."
        NoProjects = "No projects found in database."
        ProjectSet = "Project root set to: {0}"
        NoBackups = "No backups found under:`n{0}"
        RollbackConfirm = "Rollback from this backup?`n`n{0}`n`nThis will overwrite current database/JSONL files listed in the manifest."
        ConfirmRollback = "Confirm rollback"
        RollbackRestored = "Rollback restored {0} file(s) from {1}"
        NoSources = "No rollout-*.jsonl sources found in common locations."
        NoSourcesLog = "No rollout-*.jsonl sources found."
        SourceSet = "Source sessions set to: {0}"
        SourcesFound = "Found {0} source candidate(s)."
        SourceSelectedHint = "Source selected. Click Find recoverable records to scan and import it."
        ExternalScan = "Source scan: {0} source(s), {1} importable chat(s), {2} already in current Codex."
        ExternalImportConfirm = "Import {0} chat(s) from {1} selected source(s)?`n`nA database backup will be created first."
        ExternalImportSkipped = "Import skipped. Current records are loaded only."
        ImportingSource = "Importing source: {0}"
        ScanningSource = "Scanning source: {0} [{1}]"
        StartupRunningPrompt = "Codex Desktop appears to be running.`n`nTo avoid crashes, database locks, or stale UI state, close Codex before restoring history.`n`nOpen this tool in read-only mode anyway?"
        StartupRunningCancelled = "Tool closed because Codex Desktop is running."
        DesktopRunningPrompt = "Codex Desktop is still running.`n`nRestoring while Codex is open may cause database conflicts or Codex UI crashes. Close Codex first, then try again.`n`nContinue anyway? This is not recommended."
        ImportRunningPrompt = "Codex Desktop is still running.`n`nImporting while Codex is open may cause database conflicts or Codex UI crashes. Close Codex first, then try again.`n`nContinue anyway? This is not recommended."
        RollbackRunningPrompt = "Codex Desktop is still running.`n`nRollback overwrites local database/session files and should not run while Codex is open. Close Codex first, then try again.`n`nContinue anyway? This is not recommended."
        OperationBlockedByRunningCodex = "Operation cancelled because Codex Desktop is running."
        RestoreConfirmPrompt = "Restore {0} selected thread(s)?`n`nProject handling: {1}`n`nA backup will be created in:`n{2}"
        KeepOriginalProjects = "keep each chat under its original project"
        MoveToProject = "move selected chats to {0}"
        NoImportable = "No importable sessions found.`n`nScanned: {0}`nExisting: {1}`nInvalid: {2}"
        ImportConfirmPrompt = "Import rollout-*.jsonl from:`n{0}`n`nScanned: {1}`nImportable: {2}`nExisting: {3}`nInvalid: {4}`n`nNew rows will be inserted into the current Codex database."
        ThreadDetailsBody = "Thread Id: {0}`r`nStatus: {1}`r`nUpdated: {2}`r`nProject: {3}`r`n`r`nTitle:`r`n{4}"
        ToolTipProject = "Optional. Leave empty to keep each recovered chat under its original project."
        ToolTipLoad = "Load current Codex records and scan common backup/VS Code/Cursor locations for chats that can be imported."
        ToolTipSelect = "Select rows whose metadata needs repair."
        ToolTipPreview = "Preview the restore without changing files."
        ToolTipRestore = "Create a backup, then repair the selected chats."
        ToolTipMore = "Open source scanning, backup rollback, logs, and advanced settings."
        ToolTipCodexHome = "Usually %USERPROFILE%\.codex. This is where Codex Desktop stores local history."
        ToolTipSource = "Optional. Use this only when importing rollout-*.jsonl files from another .codex\sessions folder."
        ToolTipBackup = "Backups are created here before Restore or Import writes anything."
        ToolTipTemplate = "Advanced. Leave blank unless you want to copy Desktop metadata from a specific visible thread."
        ToolTipHiddenOnly = "When loading records, show only chats whose metadata needs repair."
        ToolTipNoTouch = "Advanced. Prevents updated_at_ms from being refreshed, so restored chats may not move to the top."
        SelectProjectFolder = "Choose project root"
        SelectSourceFolder = "Choose external .codex sessions folder"
        SelectBackupFolder = "Choose backup folder"
        DataLocations = "Data locations"
        SafetyRollback = "Safety and rollback"
        ExpertOptions = "Repair options"
    }
    zh = @{
        AppTitle = "Codex 历史恢复工具"
        HeroTitle = "恢复 Codex 对话"
        HeroSubtitle = "查找可恢复记录，选择要修复的对话，然后恢复。导入或最终恢复前不会写入数据。"
        NextChooseProject = "下一步：点击「查找可恢复记录」。工具会同时检查备份和其他 Codex 文件夹。"
        NextEnvIssue = "下一步：打开「更多工具 > 重新检测环境」。如果缺少 sqlite3，请把 sqlite3.exe 放到 tools 文件夹或加入 PATH。"
        NextLoad = "下一步：点击「查找可恢复记录」。外部来源会先扫描，只有确认后才导入。"
        NextSelect = "下一步：点击「选择需修复」，或手动勾选要恢复的行。通常恢复「需修复」行即可。"
        NextPreview = "下一步：点击「恢复所选」。写入前会先自动创建备份。"
        PreviewComplete = "预览完成。如果所选记录正确，请点击「恢复所选」。"
        PreviewDialogTitle = "恢复预览"
        PreviewDialogBody = "没有修改任何文件。`n`n模板：{0}`n已选：{1}`n项目处理：{2}`n`n对话：`n{3}"
        PreviewMore = "... 另有 {0} 条"
        RestoreComplete = "恢复完成。请回到 Codex Desktop，切换项目或重启 Codex 后查看恢复的对话。"
        ImportComplete = "导入完成。记录已加载，请继续选择并恢复需修复记录。"
        EnvChecking = "环境：检测中..."
        EnvNotChecked = "环境：未检测"
        EnvReady = "环境：已就绪"
        EnvNeedsAttention = "环境：需要处理"
        ProjectNotSelected = "项目：保留原项目"
        ProjectPrefix = "移动到项目：{0}"
        RecordsNotLoaded = "记录：未加载"
        RecordsLoaded = "记录：已加载 {0} 条，其中 {1} 条需修复"
        SelectedCount = "已选：{0}"
        RestoreInto = "项目覆盖"
        ChooseProject = "选择项目"
        BrowseFolder = "浏览文件夹"
        SimpleHelp = "从「查找可恢复记录」开始。如果记录在当前 Codex 之外，会让你选择要导入的来源。"
        LoadRecords = "查找可恢复记录"
        SelectHidden = "选择需修复"
        Preview = "预览"
        RestoreSelected = "恢复所选"
        MoreTools = "更多工具..."
        CodexHome = "Codex 目录"
        ReCheck = "重新检测"
        ImportSource = "导入来源"
        Browse = "浏览"
        FindSources = "查找来源"
        BackupFolder = "备份目录"
        Rollback = "回滚"
        TemplateThread = "模板对话"
        HiddenOnly = "只看需修复"
        DoNotBump = "不置顶"
        Search = "搜索"
        All = "全部"
        Hidden = "需修复"
        Visible = "可见"
        Status = "状态"
        Title = "标题"
        ThreadId = "对话 ID"
        Updated = "更新时间"
        Project = "项目"
        Threads = "对话数"
        Created = "创建时间"
        Operation = "操作"
        Manifest = "清单"
        Path = "路径"
        LastWrite = "最后修改"
        Kind = "类型"
        Language = "语言"
        ShowAdvanced = "设置与恢复..."
        HideAdvanced = "隐藏设置"
        ClearSelection = "清除选择"
        ShowLog = "显示日志"
        HideLog = "隐藏日志"
        ImportSessions = "导入已填写来源..."
        ScanOtherSources = "查找其他位置的对话..."
        ImportFoundSources = "导入所选来源"
        ImportFoundTitle = "导入找到的来源"
        ImportFoundHelp = "这些文件夹里的对话还不在当前 Codex 数据库中。请勾选要导入的来源。"
        SourcePreview = "预览"
        EmptyStateTitle = "尚未加载记录"
        EmptyStateBody = "点击「查找可恢复记录」扫描当前 Codex、备份和其他本地 Codex 文件夹。"
        EmptyFilterTitle = "没有符合筛选的记录"
        EmptyFilterBody = "可切换到「全部」、清空搜索，或重新点击「查找可恢复记录」。"
        TemplateHelp = "没有找到可作为模板的可见 Codex 对话。请先在 Codex Desktop 新建一条普通对话，然后点击「重新检测」。"
        BackupsRollback = "备份 / 回滚"
        ReCheckEnvironment = "重新检测环境"
        UseSelected = "使用所选"
        Cancel = "取消"
        Close = "关闭"
        RollbackSelected = "回滚所选备份"
        ChooseProjectRoot = "选择项目"
        ThreadDetails = "对话详情"
        ConfirmRestore = "确认恢复"
        ConfirmImport = "确认导入"
        CodexRunningTitle = "Codex 正在运行"
        ImportSessionsTitle = "导入 Sessions"
        FindSourcesTitle = "查找来源"
        ChooseSourceTitle = "选择 Sessions 来源文件夹"
        ErrorPrefix = "错误：{0}"
        EnvironmentOk = "环境正常。"
        EnvironmentIssues = "环境存在问题。"
        CodexHomeLog = "Codex 目录：{0}"
        DatabaseLog = "数据库：{0}"
        TemplateLog = "模板对话：{0}"
        DesktopRunningWarning = "警告：Codex Desktop 似乎正在运行。恢复、导入或回滚前请先关闭 Codex。"
        DbNotFound = "找不到 Codex 数据库：{0}"
        LoadedThreads = "已加载 {0} 条对话。"
        ShowingThreads = "当前显示 {0} / {1} 条对话。"
        SelectedHiddenRows = "已选择所有需修复记录。"
        SelectionCleared = "已清除选择。"
        SelectAtLeastOne = "请至少选择一条对话。"
        DryRunNoChanges = "正在预览，不会修改任何文件。"
        WouldRestore = "将恢复 {0} 条对话："
        RestoreCancelled = "已取消恢复。"
        BackupCreated = "已创建备份：{0}"
        RestoredThreads = "已恢复 {0} 条对话。"
        ChooseExternalFirst = "请先选择外部 sessions 文件夹。"
        ImportScan = "导入扫描：共扫描={0} 可导入={1} 已存在={2} 无效={3}"
        ImportCancelled = "已取消导入。"
        DatabaseBackupCreated = "已创建数据库备份：{0}"
        ImportResult = "已扫描 {0} 个 JSONL 文件。导入 {1} 个，已存在={2}，无效={3}。"
        NoProjects = "数据库中没有找到项目。"
        ProjectSet = "项目已设置为：{0}"
        NoBackups = "没有在以下位置找到备份：`n{0}"
        RollbackConfirm = "要从这个备份回滚吗？`n`n{0}`n`n这会覆盖 manifest 中列出的当前数据库/JSONL 文件。"
        ConfirmRollback = "确认回滚"
        RollbackRestored = "已从 {1} 回滚 {0} 个文件。"
        NoSources = "常见位置中没有找到 rollout-*.jsonl 来源。"
        NoSourcesLog = "没有找到 rollout-*.jsonl 来源。"
        SourceSet = "Sessions 来源已设置为：{0}"
        SourcesFound = "找到 {0} 个来源候选。"
        SourceSelectedHint = "已选择来源。点击「查找可恢复记录」即可扫描并导入它。"
        ExternalScan = "来源扫描：{0} 个来源，{1} 条可导入对话，{2} 条已在当前 Codex 中。"
        ExternalImportConfirm = "要从 {1} 个所选来源导入 {0} 条对话吗？`n`n导入前会先创建数据库备份。"
        ExternalImportSkipped = "已跳过导入。当前记录已加载。"
        ImportingSource = "正在导入来源：{0}"
        ScanningSource = "正在扫描来源：{0} [{1}]"
        StartupRunningPrompt = "检测到 Codex Desktop 正在运行。`n`n为避免闪退、数据库锁或界面状态异常，建议先关闭 Codex 再恢复历史记录。`n`n仍要以只读模式打开此工具吗？"
        StartupRunningCancelled = "因 Codex Desktop 正在运行，已关闭工具。"
        DesktopRunningPrompt = "Codex Desktop 仍在运行。`n`n在 Codex 打开时恢复，可能导致数据库冲突或 Codex 界面闪退。请先关闭 Codex，再重试。`n`n仍要继续吗？不推荐这样做。"
        ImportRunningPrompt = "Codex Desktop 仍在运行。`n`n在 Codex 打开时导入，可能导致数据库冲突或 Codex 界面闪退。请先关闭 Codex，再重试。`n`n仍要继续吗？不推荐这样做。"
        RollbackRunningPrompt = "Codex Desktop 仍在运行。`n`n回滚会覆盖本地数据库/session 文件，不应在 Codex 打开时执行。请先关闭 Codex，再重试。`n`n仍要继续吗？不推荐这样做。"
        OperationBlockedByRunningCodex = "因 Codex Desktop 正在运行，已取消操作。"
        RestoreConfirmPrompt = "要恢复所选 {0} 条对话吗？`n`n项目处理：{1}`n`n将会先在这里创建备份：`n{2}"
        KeepOriginalProjects = "保留每条对话原本所属项目"
        MoveToProject = "移动所选对话到 {0}"
        NoImportable = "没有可导入的 sessions。`n`n扫描：{0}`n已存在：{1}`n无效：{2}"
        ImportConfirmPrompt = "要从以下位置导入 rollout-*.jsonl 吗？`n{0}`n`n扫描：{1}`n可导入：{2}`n已存在：{3}`n无效：{4}`n`n新记录将写入当前 Codex 数据库。"
        ThreadDetailsBody = "对话 ID：{0}`r`n状态：{1}`r`n更新时间：{2}`r`n项目：{3}`r`n`r`n标题：`r`n{4}"
        ToolTipProject = "可选。留空会保留每条对话原本所属项目。"
        ToolTipLoad = "加载当前 Codex 记录，并扫描常见备份、VS Code、Cursor 位置中可导入的对话。"
        ToolTipSelect = "选择元数据需要修复的记录。"
        ToolTipPreview = "只预览恢复内容，不修改文件。"
        ToolTipRestore = "先创建备份，然后修复所选对话。"
        ToolTipMore = "打开来源扫描、备份回滚、日志和高级设置。"
        ToolTipCodexHome = "通常是 %USERPROFILE%\.codex，Codex Desktop 会在这里保存本地历史。"
        ToolTipSource = "可选。只有从另一个 .codex\sessions 文件夹导入 rollout-*.jsonl 时才需要。"
        ToolTipBackup = "恢复或导入写入前，会先在这里创建备份。"
        ToolTipTemplate = "高级选项。默认留空即可，除非要从指定可见对话复制 Desktop 元数据。"
        ToolTipHiddenOnly = "加载记录时，只显示元数据需要修复的对话。"
        ToolTipNoTouch = "高级选项。不刷新 updated_at_ms，恢复后对话可能不会移动到列表顶部。"
        SelectProjectFolder = "选择项目文件夹"
        SelectSourceFolder = "选择外部 .codex sessions 文件夹"
        SelectBackupFolder = "选择备份文件夹"
        DataLocations = "数据位置"
        SafetyRollback = "备份与回滚"
        ExpertOptions = "修复选项"
    }
}

function T {
    param([string] $Key, [Parameter(ValueFromRemainingArguments = $true)] [object[]] $Args)
    $text = $script:Strings[$script:Language][$Key]
    if ($null -eq $text) { $text = $script:Strings["en"][$Key] }
    if ($null -eq $text) { return $Key }
    if ($Args.Count -eq 1 -and $Args[0] -is [System.Array]) { $Args = @($Args[0]) }
    if ($Args.Count -gt 0) { return ($text -f $Args) }
    return $text
}

function Get-CHRStatusKeyFromDisplay {
    param([string] $Text)
    switch ($Text) {
        { $_ -eq (T "Hidden") -or $_ -eq "Hidden" -or $_ -eq "Needs repair" -or $_ -eq "Old" -or $_ -eq "隐藏" -or $_ -eq "需修复" } { return "old" }
        { $_ -eq (T "Visible") -or $_ -eq "Visible" -or $_ -eq "Ready" -or $_ -eq "Desktop" -or $_ -eq "可见" } { return "desktop" }
        default { return "" }
    }
}

function New-CHRFont {
    param([float] $Size = 9, [System.Drawing.FontStyle] $Style = [System.Drawing.FontStyle]::Regular)
    return New-Object System.Drawing.Font("Segoe UI", $Size, $Style)
}

function Add-Log {
    param([string] $Message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $txtLog.AppendText("[$timestamp] $Message`r`n")
}

function Get-DbPathFromUi {
    return (Join-Path $txtCodexHome.Text "state_5.sqlite")
}

function Get-ProjectDbCwdFromUi {
    if ([string]::IsNullOrWhiteSpace($txtProjectRoot.Text)) { return "" }
    return ConvertTo-CHRDbCwd -Path $txtProjectRoot.Text
}

function Get-ProjectJsonCwdFromUi {
    if ([string]::IsNullOrWhiteSpace($txtProjectRoot.Text)) { return "" }
    return ConvertTo-CHRJsonCwd -Path $txtProjectRoot.Text
}

function Show-Error {
    param([string] $Message)
    Add-Log (T "ErrorPrefix" @($Message))
    [System.Windows.Forms.MessageBox]::Show($Message, (T "AppTitle"), [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
}

function Set-Busy {
    param([bool] $Busy)
    $script:IsBusy = $Busy
    $form.Cursor = if ($Busy) { [System.Windows.Forms.Cursors]::WaitCursor } else { [System.Windows.Forms.Cursors]::Default }
    foreach ($control in @($btnDetect, $btnDetectAction, $btnBrowseProject, $btnChooseProject, $btnChooseProjectAction, $btnBrowseSource, $btnFindSources, $btnFindSourcesAction, $btnBrowseBackup, $btnLoad, $btnImport, $btnDryRun, $btnRestore, $btnSelectOld, $btnClearSelection, $btnBackups, $btnMoreTools, $btnShowLog, $txtSearch, $cmbStatusFilter)) {
        if (-not $control) { continue }
        $control.Enabled = -not $Busy
    }
    if (-not $Busy -and (Get-Variable -Name btnLoad -ErrorAction SilentlyContinue)) { Update-ControlState }
    [System.Windows.Forms.Application]::DoEvents()
}

function Invoke-Safe {
    param([scriptblock] $Action)
    Set-Busy $true
    try {
        & $Action
    } catch {
        Show-Error $_.Exception.Message
    } finally {
        Set-Busy $false
    }
}

function Select-Folder {
    param([string] $Description, [string] $InitialPath = "")
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = $Description
    $dialog.ShowNewFolderButton = $true
    if ($InitialPath -and (Test-Path -LiteralPath $InitialPath)) {
        $dialog.SelectedPath = $InitialPath
    }
    if ($dialog.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.SelectedPath
    }
    return ""
}

function Confirm-CHRWhenCodexRunning {
    param([string] $PromptKey)
    return $true
}

function Invoke-Detect {
    $envInfo = Test-CHREnvironment -CodexHome $txtCodexHome.Text
    $script:LastEnvironment = $envInfo
    if ($envInfo.Ok) {
        Add-Log (T "EnvironmentOk")
    } else {
        Add-Log (T "EnvironmentIssues")
        foreach ($err in $envInfo.Errors) { Add-Log " - $err" }
    }
    Add-Log (T "CodexHomeLog" @($envInfo.CodexHome))
    Add-Log (T "DatabaseLog" @($envInfo.Database))
    if ($envInfo.SqlitePath) { Add-Log "sqlite3: $($envInfo.SqlitePath)" }
    if ($envInfo.TemplateThreadId) { Add-Log (T "TemplateLog" @($envInfo.TemplateThreadId)) }
    if (-not $envInfo.TemplateOk) { Add-Log (T "TemplateHelp") }
    Update-Guidance
}

function Load-Threads {
    $db = Get-DbPathFromUi
    if (-not (Test-Path -LiteralPath $db)) { throw (T "DbNotFound" @($db)) }
    $projectDbCwd = Get-ProjectDbCwdFromUi
    $script:Rows = @(Get-CHRThreadRows -Database $db -ProjectDbCwd $projectDbCwd -OldOnly:$chkOnlyOld.Checked)
    Apply-GridFilter
    Add-Log (T "LoadedThreads" @($script:Rows.Count))
    Update-Guidance
}

function Select-CHRImportSources {
    param([object[]] $SourceScans)
    $script:CHRSelectedImportSources = @()

    $picker = New-Object System.Windows.Forms.Form
    $picker.Text = T "ImportFoundTitle"
    $picker.StartPosition = "CenterParent"
    $picker.Size = New-Object System.Drawing.Size(1080, 500)
    $picker.MinimumSize = New-Object System.Drawing.Size(760, 360)
    $picker.Font = New-CHRFont 9

    $layout = New-Object System.Windows.Forms.TableLayoutPanel
    $layout.Dock = [System.Windows.Forms.DockStyle]::Fill
    $layout.RowCount = 3
    $layout.ColumnCount = 1
    $layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 46))) | Out-Null
    $layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
    $layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 50))) | Out-Null
    $picker.Controls.Add($layout)

    $help = New-Object System.Windows.Forms.Label
    $help.Text = T "ImportFoundHelp"
    $help.Dock = [System.Windows.Forms.DockStyle]::Fill
    $help.Padding = New-Object System.Windows.Forms.Padding(12, 8, 12, 4)
    $layout.Controls.Add($help, 0, 0)

    $list = New-Object System.Windows.Forms.ListView
    $list.Dock = [System.Windows.Forms.DockStyle]::Fill
    $list.View = [System.Windows.Forms.View]::Details
    $list.CheckBoxes = $true
    $list.FullRowSelect = $true
    $list.HideSelection = $false
    $list.Columns.Add((T "Path"), 360) | Out-Null
    $list.Columns.Add((T "Kind"), 105) | Out-Null
    $list.Columns.Add("New", 70) | Out-Null
    $list.Columns.Add("Existing", 80) | Out-Null
    $list.Columns.Add("Invalid", 70) | Out-Null
    $list.Columns.Add((T "SourcePreview"), 260) | Out-Null
    $list.Columns.Add((T "LastWrite"), 140) | Out-Null

    foreach ($entry in $SourceScans) {
        $item = New-Object System.Windows.Forms.ListViewItem($entry.Source.Path)
        $item.Checked = ($entry.Scan.Importable -gt 0)
        $previewTitles = @($entry.Scan.Items | Where-Object { $_.Status -eq "Importable" } | Select-Object -First 3 | ForEach-Object { Get-CHRShortTitle $_.Title 42 })
        $item.SubItems.Add($entry.Source.SourceKind) | Out-Null
        $item.SubItems.Add([string]$entry.Scan.Importable) | Out-Null
        $item.SubItems.Add([string]$entry.Scan.Existing) | Out-Null
        $item.SubItems.Add([string]$entry.Scan.Invalid) | Out-Null
        $item.SubItems.Add(($previewTitles -join " / ")) | Out-Null
        $item.SubItems.Add($entry.Source.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")) | Out-Null
        $item.Tag = $entry
        $list.Items.Add($item) | Out-Null
    }
    $layout.Controls.Add($list, 0, 1)

    $buttons = New-Object System.Windows.Forms.FlowLayoutPanel
    $buttons.Dock = [System.Windows.Forms.DockStyle]::Fill
    $buttons.FlowDirection = [System.Windows.Forms.FlowDirection]::RightToLeft
    $buttons.Padding = New-Object System.Windows.Forms.Padding(8)
    $btnOk = New-Object System.Windows.Forms.Button
    $btnOk.Text = T "ImportFoundSources"
    $btnOk.Width = 150
    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = T "Cancel"
    $btnCancel.Width = 90
    $buttons.Controls.Add($btnOk)
    $buttons.Controls.Add($btnCancel)
    $layout.Controls.Add($buttons, 0, 2)

    $btnOk.Add_Click({
        $selected = @()
        foreach ($item in $list.Items) {
            if ($item.Checked -and $item.Tag.Scan.Importable -gt 0) { $selected += $item.Tag }
        }
        $script:CHRSelectedImportSources = @($selected)
        $picker.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $picker.Close()
    })
    $btnCancel.Add_Click({
        $script:CHRSelectedImportSources = @()
        $picker.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $picker.Close()
    })
    [void]$picker.ShowDialog($form)
    return @($script:CHRSelectedImportSources)
}

function Invoke-FindRecoverableRecords {
    if (-not $script:LastEnvironment) { Invoke-Detect }
    Load-Threads

    $db = Get-DbPathFromUi
    $extra = @()
    if (-not [string]::IsNullOrWhiteSpace($txtSourceSessions.Text)) { $extra += $txtSourceSessions.Text }
    if (-not [string]::IsNullOrWhiteSpace($txtBackupRoot.Text)) { $extra += $txtBackupRoot.Text }
    $sources = @(Find-CHRSources -CodexHome $txtCodexHome.Text -ExtraRoots $extra | Where-Object { -not $_.IsCurrentCodex })

    $sourceScans = @()
    foreach ($source in $sources) {
        try {
            Add-Log (T "ScanningSource" @($source.Path, $source.SourceKind))
            $scan = Test-CHRImportSessions -Database $db -SessionsDir $source.Path
            if (($scan.Importable + $scan.Existing + $scan.Invalid) -gt 0) {
                $sourceScans += [pscustomobject]@{ Source = $source; Scan = $scan }
            }
        } catch {
            Add-Log (T "ErrorPrefix" @("$($source.Path): $($_.Exception.Message)"))
        }
    }

    $importable = 0
    $existing = 0
    foreach ($entry in $sourceScans) {
        $importable += [int]$entry.Scan.Importable
        $existing += [int]$entry.Scan.Existing
    }
    Add-Log (T "ExternalScan" @($sourceScans.Count, $importable, $existing))

    if ($importable -le 0) {
        Update-Guidance
        return
    }

    $selectedSources = Select-CHRImportSources -SourceScans @($sourceScans | Where-Object { $_.Scan.Importable -gt 0 })
    if ($selectedSources.Count -eq 0) {
        Add-Log (T "ExternalImportSkipped")
        Update-Guidance
        return
    }

    $selectedImportable = 0
    foreach ($entry in $selectedSources) { $selectedImportable += [int]$entry.Scan.Importable }
    $confirm = [System.Windows.Forms.MessageBox]::Show(
        (T "ExternalImportConfirm" @($selectedImportable, $selectedSources.Count)),
        (T "ImportFoundTitle"),
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) {
        Add-Log (T "ExternalImportSkipped")
        Update-Guidance
        return
    }

    $template = Get-TemplateFromUi
    $backup = New-CHRBackup -Database $db -JsonlPaths @() -BackupRoot $txtBackupRoot.Text -Operation "import" -CodexHome $txtCodexHome.Text -ProjectRoot (Get-ProjectJsonCwdFromUi)
    Add-Log (T "DatabaseBackupCreated" @($backup))
    $totalImported = 0
    $totalScanned = 0
    $totalExisting = 0
    $totalInvalid = 0
    foreach ($entry in $selectedSources) {
        Add-Log (T "ImportingSource" @($entry.Source.Path))
        $result = Import-CHRJsonlSessions -Database $db -CodexHome $txtCodexHome.Text -SessionsDir $entry.Source.Path -ProjectDbCwd (Get-ProjectDbCwdFromUi) -ProjectJsonCwd (Get-ProjectJsonCwdFromUi) -Template $template
        $totalImported += @($result.Imported).Count
        $totalScanned += [int]$result.Scanned
        $totalExisting += [int]$result.Existing
        $totalInvalid += [int]$result.Invalid
    }
    Add-Log (T "ImportResult" @($totalScanned, $totalImported, $totalExisting, $totalInvalid))
    $chkOnlyOld.Checked = $true
    $cmbStatusFilter.SelectedItem = T "Hidden"
    Load-Threads
    Update-Guidance (T "ImportComplete")
}

function Apply-GridFilter {
    $query = $txtSearch.Text.Trim()
    $status = [string]$cmbStatusFilter.SelectedItem
    $statusKey = Get-CHRStatusKeyFromDisplay $status
    $grid.Rows.Clear()
    $displayRows = @($script:Rows | Where-Object {
        $matchStatus = ([string]::IsNullOrWhiteSpace($statusKey) -or $_.Status -eq $statusKey)
        $matchText = (-not $query) -or ($_.Title -like "*$query*") -or ($_.Id -like "*$query*") -or ($_.Cwd -like "*$query*")
        $matchStatus -and $matchText
    })
    foreach ($row in $displayRows) {
        $idx = $grid.Rows.Add()
        $grid.Rows[$idx].Cells["Selected"].Value = $false
        $grid.Rows[$idx].Cells["Number"].Value = $row.Number
        $grid.Rows[$idx].Cells["Status"].Value = if ($row.Status -eq "old") { T "Hidden" } else { T "Visible" }
        $grid.Rows[$idx].Cells["Title"].Value = Get-CHRShortTitle $row.Title 160
        $grid.Rows[$idx].Cells["ThreadId"].Value = $row.Id
        $grid.Rows[$idx].Cells["UpdatedAt"].Value = $row.UpdatedAt.ToString("yyyy-MM-dd HH:mm:ss")
        $grid.Rows[$idx].Cells["Project"].Value = ($row.Cwd -replace "^\\\\\?\\", "")
        if ($row.Status -eq "old") {
            $grid.Rows[$idx].DefaultCellStyle.ForeColor = [System.Drawing.Color]::FromArgb(145, 92, 0)
        } else {
            $grid.Rows[$idx].DefaultCellStyle.ForeColor = [System.Drawing.Color]::FromArgb(35, 105, 70)
        }
    }
    Add-Log (T "ShowingThreads" @($displayRows.Count, $script:Rows.Count))
    Update-Guidance
}

function Update-EmptyState {
    if (-not (Get-Variable -Name lblEmptyStateTitle -ErrorAction SilentlyContinue)) { return }
    $showEmpty = ($grid.Rows.Count -eq 0)
    $lblEmptyStateTitle.Visible = $showEmpty
    $lblEmptyStateBody.Visible = $showEmpty
    if (-not $showEmpty) { return }
    if ($script:Rows.Count -eq 0) {
        $lblEmptyStateTitle.Text = T "EmptyStateTitle"
        $lblEmptyStateBody.Text = T "EmptyStateBody"
    } else {
        $lblEmptyStateTitle.Text = T "EmptyFilterTitle"
        $lblEmptyStateBody.Text = T "EmptyFilterBody"
    }
}

function Get-SelectedRowsFromGrid {
    $selected = @()
    foreach ($gridRow in $grid.Rows) {
        if ($gridRow.IsNewRow) { continue }
        if ([bool]$gridRow.Cells["Selected"].Value) {
            $id = [string]$gridRow.Cells["ThreadId"].Value
            $match = $script:Rows | Where-Object { $_.Id -eq $id } | Select-Object -First 1
            if ($match) { $selected += $match }
        }
    }
    return @($selected)
}

function Select-OldRows {
    foreach ($gridRow in $grid.Rows) {
        if ($gridRow.IsNewRow) { continue }
        $gridRow.Cells["Selected"].Value = ((Get-CHRStatusKeyFromDisplay ([string]$gridRow.Cells["Status"].Value)) -eq "old")
    }
    Add-Log (T "SelectedHiddenRows")
    Update-Guidance
}

function Clear-SelectedRows {
    foreach ($gridRow in $grid.Rows) {
        if ($gridRow.IsNewRow) { continue }
        $gridRow.Cells["Selected"].Value = $false
    }
    Add-Log (T "SelectionCleared")
    Update-Guidance
}

function Update-ControlState {
    if ($script:IsBusy) { return }
    if (-not (Get-Variable -Name btnLoad -ErrorAction SilentlyContinue)) { return }
    $hasRows = ($script:Rows.Count -gt 0)
    $hasRepairableRows = (@($script:Rows | Where-Object { $_.Status -eq "old" }).Count -gt 0)
    $selectedCount = 0
    if ((Get-Variable -Name grid -ErrorAction SilentlyContinue) -and $grid.Columns.Count -gt 0) {
        foreach ($gridRow in $grid.Rows) {
            if ($gridRow.IsNewRow) { continue }
            if ([bool]$gridRow.Cells["Selected"].Value) { $selectedCount++ }
        }
    }
    $btnLoad.Enabled = $true
    $btnMoreTools.Enabled = $true
    $txtSearch.Enabled = $hasRows
    $cmbStatusFilter.Enabled = $hasRows
    $btnSelectOld.Enabled = $hasRows -and $hasRepairableRows
    $btnRestore.Enabled = ($selectedCount -gt 0)
}

function Update-Guidance {
    param([string] $Hint = "")

    if (-not (Get-Variable -Name lblNextStep -ErrorAction SilentlyContinue)) { return }

    $envText = T "EnvNotChecked"
    $envColor = [System.Drawing.Color]::FromArgb(96, 96, 96)
    if ($script:LastEnvironment) {
        if ($script:LastEnvironment.Ok) {
            $envText = T "EnvReady"
            $envColor = [System.Drawing.Color]::FromArgb(23, 118, 72)
        } else {
            $envText = T "EnvNeedsAttention"
            $envColor = [System.Drawing.Color]::FromArgb(180, 72, 28)
        }
    }

    $projectText = if ([string]::IsNullOrWhiteSpace($txtProjectRoot.Text)) { T "ProjectNotSelected" } else { T "ProjectPrefix" @($txtProjectRoot.Text) }
    $rowText = if ($script:Rows.Count -gt 0) {
        $oldCount = @($script:Rows | Where-Object { $_.Status -eq "old" }).Count
        T "RecordsLoaded" @($script:Rows.Count, $oldCount)
    } else {
        T "RecordsNotLoaded"
    }
    $selectedCount = 0
    if ((Get-Variable -Name grid -ErrorAction SilentlyContinue) -and $grid.Columns.Count -gt 0) {
        foreach ($gridRow in $grid.Rows) {
            if ($gridRow.IsNewRow) { continue }
            if ([bool]$gridRow.Cells["Selected"].Value) { $selectedCount++ }
        }
    }
    $selectionText = T "SelectedCount" @($selectedCount)

    if ($Hint) {
        $next = $Hint
    } elseif (-not $script:LastEnvironment -or -not $script:LastEnvironment.Ok) {
        $next = T "NextEnvIssue"
    } elseif ($script:Rows.Count -eq 0) {
        $next = if ([string]::IsNullOrWhiteSpace($txtProjectRoot.Text)) { T "NextChooseProject" } else { T "NextLoad" }
    } elseif ($selectedCount -eq 0) {
        $next = T "NextSelect"
    } else {
        $next = T "NextPreview"
    }

    $lblNextStep.Text = $next
    $lblEnvStatus.Text = $envText
    $lblEnvStatus.ForeColor = $envColor
    $lblProjectStatus.Text = $projectText
    $lblRowsStatus.Text = $rowText
    $lblSelectedStatus.Text = $selectionText
    Update-EmptyState
    Update-ControlState
}

function Get-TemplateFromUi {
    return Get-CHRTemplate -Database (Get-DbPathFromUi) -RequestedThreadId $txtTemplateThreadId.Text.Trim()
}

function Invoke-DryRun {
    $selected = Get-SelectedRowsFromGrid
    if ($selected.Count -eq 0) { throw (T "SelectAtLeastOne") }
    $template = Get-TemplateFromUi
    $projectMode = if ([string]::IsNullOrWhiteSpace($txtProjectRoot.Text)) { T "KeepOriginalProjects" } else { T "MoveToProject" @($txtProjectRoot.Text) }
    Add-Log (T "DryRunNoChanges")
    Add-Log (T "TemplateLog" @($template.Id))
    Add-Log (T "WouldRestore" @($selected.Count))
    foreach ($row in $selected) {
        Add-Log " - $($row.Id) $(Get-CHRShortTitle $row.Title 80)"
    }
    $previewLines = @()
    foreach ($row in @($selected | Select-Object -First 12)) {
        $previewLines += ("- {0}  {1}" -f $row.Id, (Get-CHRShortTitle $row.Title 70))
    }
    if ($selected.Count -gt 12) {
        $previewLines += (T "PreviewMore" @($selected.Count - 12))
    }
    $body = T "PreviewDialogBody" @($template.Id, $selected.Count, $projectMode, ($previewLines -join "`n"))
    [System.Windows.Forms.MessageBox]::Show($body, (T "PreviewDialogTitle"), [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
    Update-Guidance (T "PreviewComplete")
}

function Invoke-RestoreSelected {
    $selected = Get-SelectedRowsFromGrid
    if ($selected.Count -eq 0) { throw (T "SelectAtLeastOne") }
    if (-not (Confirm-CHRWhenCodexRunning "DesktopRunningPrompt")) { Add-Log (T "RestoreCancelled"); return }
    $projectMode = if ([string]::IsNullOrWhiteSpace($txtProjectRoot.Text)) { T "KeepOriginalProjects" } else { T "MoveToProject" @($txtProjectRoot.Text) }
    $message = T "RestoreConfirmPrompt" @($selected.Count, $projectMode, $txtBackupRoot.Text)
    $confirm = [System.Windows.Forms.MessageBox]::Show($message, (T "ConfirmRestore"), [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) {
        Add-Log (T "RestoreCancelled")
        return
    }
    $db = Get-DbPathFromUi
    $template = Get-TemplateFromUi
    $paths = Get-CHRRolloutPaths -Database $db -Rows $selected
    $backup = New-CHRBackup -Database $db -JsonlPaths $paths -BackupRoot $txtBackupRoot.Text -Operation "restore" -CodexHome $txtCodexHome.Text -ProjectRoot (Get-ProjectJsonCwdFromUi) -Rows $selected
    Add-Log (T "BackupCreated" @($backup))
    Invoke-CHRSqlite -Database $db -Sql "pragma wal_checkpoint(full);" | Out-Null
    $changed = Repair-CHRThreads -Database $db -Rows $selected -ProjectDbCwd (Get-ProjectDbCwdFromUi) -ProjectJsonCwd (Get-ProjectJsonCwdFromUi) -Template $template -NoTouch:$chkNoTouch.Checked
    Add-Log (T "RestoredThreads" @(@($changed).Count))
    Load-Threads
    Update-Guidance (T "RestoreComplete")
    [System.Windows.Forms.MessageBox]::Show((T "RestoreComplete"), (T "AppTitle"), [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
}

function Invoke-ImportSessions {
    if ([string]::IsNullOrWhiteSpace($txtSourceSessions.Text)) { throw (T "ChooseExternalFirst") }
    $db = Get-DbPathFromUi
    $template = Get-TemplateFromUi
    $scan = Test-CHRImportSessions -Database $db -SessionsDir $txtSourceSessions.Text
    Add-Log (T "ImportScan" @($scan.Scanned, $scan.Importable, $scan.Existing, $scan.Invalid))
    if ($scan.Importable -eq 0) {
        [System.Windows.Forms.MessageBox]::Show((T "NoImportable" @($scan.Scanned, $scan.Existing, $scan.Invalid)), (T "ImportSessionsTitle"), [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
        return
    }
    if (-not (Confirm-CHRWhenCodexRunning "ImportRunningPrompt")) { Add-Log (T "ImportCancelled"); return }
    $message = T "ImportConfirmPrompt" @($txtSourceSessions.Text, $scan.Scanned, $scan.Importable, $scan.Existing, $scan.Invalid)
    $confirm = [System.Windows.Forms.MessageBox]::Show($message, (T "ConfirmImport"), [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) {
        Add-Log (T "ImportCancelled")
        return
    }
    $backup = New-CHRBackup -Database $db -JsonlPaths @() -BackupRoot $txtBackupRoot.Text -Operation "import" -CodexHome $txtCodexHome.Text -ProjectRoot (Get-ProjectJsonCwdFromUi)
    Add-Log (T "DatabaseBackupCreated" @($backup))
    $result = Import-CHRJsonlSessions -Database $db -CodexHome $txtCodexHome.Text -SessionsDir $txtSourceSessions.Text -ProjectDbCwd (Get-ProjectDbCwdFromUi) -ProjectJsonCwd (Get-ProjectJsonCwdFromUi) -Template $template
    Add-Log (T "ImportResult" @($result.Scanned, @($result.Imported).Count, $result.Existing, $result.Invalid))
    $chkOnlyOld.Checked = $true
    $cmbStatusFilter.SelectedItem = T "Hidden"
    Load-Threads
    Update-Guidance (T "ImportComplete")
}

function Invoke-ChooseProject {
    $db = Get-DbPathFromUi
    if (-not (Test-Path -LiteralPath $db)) { throw (T "DbNotFound" @($db)) }
    $projects = @(Get-CHRProjects -Database $db)
    if ($projects.Count -eq 0) { throw (T "NoProjects") }
    $picker = New-Object System.Windows.Forms.Form
    $picker.Text = T "ChooseProjectRoot"
    $picker.StartPosition = "CenterParent"
    $picker.Size = New-Object System.Drawing.Size(780, 420)
    $picker.Font = New-CHRFont 9
    $layout = New-Object System.Windows.Forms.TableLayoutPanel
    $layout.Dock = [System.Windows.Forms.DockStyle]::Fill
    $layout.RowCount = 2
    $layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
    $layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 46))) | Out-Null
    $picker.Controls.Add($layout)
    $list = New-Object System.Windows.Forms.ListView
    $list.Dock = [System.Windows.Forms.DockStyle]::Fill
    $list.View = [System.Windows.Forms.View]::Details
    $list.FullRowSelect = $true
    $list.Columns.Add((T "Project"), 600) | Out-Null
    $list.Columns.Add((T "Threads"), 90) | Out-Null
    foreach ($project in $projects) {
        $item = New-Object System.Windows.Forms.ListViewItem($project.Path)
        $item.SubItems.Add([string]$project.Count) | Out-Null
        $item.Tag = $project
        $list.Items.Add($item) | Out-Null
    }
    if ($list.Items.Count -gt 0) { $list.Items[0].Selected = $true }
    $layout.Controls.Add($list, 0, 0)
    $buttons = New-Object System.Windows.Forms.FlowLayoutPanel
    $buttons.Dock = [System.Windows.Forms.DockStyle]::Fill
    $buttons.FlowDirection = [System.Windows.Forms.FlowDirection]::RightToLeft
    $buttons.Padding = New-Object System.Windows.Forms.Padding(8)
    $btnOk = New-Object System.Windows.Forms.Button
    $btnOk.Text = T "UseSelected"
    $btnOk.Width = 110
    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = T "Cancel"
    $btnCancel.Width = 90
    $buttons.Controls.Add($btnOk)
    $buttons.Controls.Add($btnCancel)
    $layout.Controls.Add($buttons, 0, 1)
    $btnOk.Add_Click({
        if ($list.SelectedItems.Count -gt 0) {
            $txtProjectRoot.Text = $list.SelectedItems[0].Tag.Path
            Add-Log (T "ProjectSet" @($txtProjectRoot.Text))
            Update-Guidance
            $picker.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $picker.Close()
        }
    })
    $btnCancel.Add_Click({ $picker.DialogResult = [System.Windows.Forms.DialogResult]::Cancel; $picker.Close() })
    $list.Add_DoubleClick({ $btnOk.PerformClick() })
    [void]$picker.ShowDialog($form)
}

function Show-ThreadDetails {
    if ($grid.CurrentRow -eq $null) { return }
    $id = [string]$grid.CurrentRow.Cells["ThreadId"].Value
    $row = $script:Rows | Where-Object { $_.Id -eq $id } | Select-Object -First 1
    if (-not $row) { return }
    $status = if ($row.Status -eq "old") { T "Hidden" } else { T "Visible" }
    $message = T "ThreadDetailsBody" @($row.Id, $status, $row.UpdatedAt, ($row.Cwd -replace '^\\\\\\?\\',''), $row.Title)
    [System.Windows.Forms.MessageBox]::Show($message, (T "ThreadDetails"), [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
}

function Invoke-Backups {
    $backups = @(Get-CHRBackups -BackupRoot $txtBackupRoot.Text)
    if ($backups.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show((T "NoBackups" @($txtBackupRoot.Text)), (T "BackupsRollback"), [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
        return
    }
    $picker = New-Object System.Windows.Forms.Form
    $picker.Text = T "BackupsRollback"
    $picker.StartPosition = "CenterParent"
    $picker.Size = New-Object System.Drawing.Size(900, 430)
    $picker.Font = New-CHRFont 9
    $layout = New-Object System.Windows.Forms.TableLayoutPanel
    $layout.Dock = [System.Windows.Forms.DockStyle]::Fill
    $layout.RowCount = 2
    $layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
    $layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 46))) | Out-Null
    $picker.Controls.Add($layout)
    $list = New-Object System.Windows.Forms.ListView
    $list.Dock = [System.Windows.Forms.DockStyle]::Fill
    $list.View = [System.Windows.Forms.View]::Details
    $list.FullRowSelect = $true
    $list.Columns.Add((T "Created"), 150) | Out-Null
    $list.Columns.Add((T "Operation"), 90) | Out-Null
    $list.Columns.Add((T "Threads"), 70) | Out-Null
    $list.Columns.Add((T "Manifest"), 70) | Out-Null
    $list.Columns.Add((T "Path"), 500) | Out-Null
    foreach ($backup in $backups) {
        $item = New-Object System.Windows.Forms.ListViewItem($backup.CreatedAt.ToString("yyyy-MM-dd HH:mm:ss"))
        $item.SubItems.Add($backup.Operation) | Out-Null
        $item.SubItems.Add([string]$backup.ThreadCount) | Out-Null
        $item.SubItems.Add([string]$backup.HasManifest) | Out-Null
        $item.SubItems.Add($backup.Path) | Out-Null
        $item.Tag = $backup
        $list.Items.Add($item) | Out-Null
    }
    if ($list.Items.Count -gt 0) { $list.Items[0].Selected = $true }
    $layout.Controls.Add($list, 0, 0)
    $buttons = New-Object System.Windows.Forms.FlowLayoutPanel
    $buttons.Dock = [System.Windows.Forms.DockStyle]::Fill
    $buttons.FlowDirection = [System.Windows.Forms.FlowDirection]::RightToLeft
    $buttons.Padding = New-Object System.Windows.Forms.Padding(8)
    $btnRollback = New-Object System.Windows.Forms.Button
    $btnRollback.Text = T "RollbackSelected"
    $btnRollback.Width = 130
    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = T "Close"
    $btnClose.Width = 90
    $buttons.Controls.Add($btnRollback)
    $buttons.Controls.Add($btnClose)
    $layout.Controls.Add($buttons, 0, 1)
    $btnRollback.Add_Click({
        if ($list.SelectedItems.Count -eq 0) { return }
        $backup = $list.SelectedItems[0].Tag
        if (-not (Confirm-CHRWhenCodexRunning "RollbackRunningPrompt")) { return }
        $confirm = [System.Windows.Forms.MessageBox]::Show((T "RollbackConfirm" @($backup.Path)), (T "ConfirmRollback"), [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) { return }
        try {
            $result = Restore-CHRBackup -BackupPath $backup.Path
            Add-Log (T "RollbackRestored" @($result.Restored, $backup.Path))
            $picker.Close()
            Load-Threads
        } catch {
            Show-Error $_.Exception.Message
        }
    })
    $btnClose.Add_Click({ $picker.Close() })
    [void]$picker.ShowDialog($form)
}

function Invoke-FindSources {
    $extra = @()
    if (-not [string]::IsNullOrWhiteSpace($txtSourceSessions.Text)) { $extra += $txtSourceSessions.Text }
    if (-not [string]::IsNullOrWhiteSpace($txtBackupRoot.Text)) { $extra += $txtBackupRoot.Text }
    $sources = @(Find-CHRSources -CodexHome $txtCodexHome.Text -ExtraRoots $extra)
    if ($sources.Count -eq 0) {
        Add-Log (T "NoSourcesLog")
        [System.Windows.Forms.MessageBox]::Show((T "NoSources"), (T "FindSourcesTitle"), [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
        return
    }

    $picker = New-Object System.Windows.Forms.Form
    $picker.Text = T "ChooseSourceTitle"
    $picker.StartPosition = "CenterParent"
    $picker.Size = New-Object System.Drawing.Size(820, 420)
    $picker.MinimumSize = New-Object System.Drawing.Size(720, 360)
    $picker.Font = New-CHRFont 9

    $layout = New-Object System.Windows.Forms.TableLayoutPanel
    $layout.Dock = [System.Windows.Forms.DockStyle]::Fill
    $layout.RowCount = 2
    $layout.ColumnCount = 1
    $layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
    $layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 46))) | Out-Null
    $picker.Controls.Add($layout)

    $list = New-Object System.Windows.Forms.ListView
    $list.Dock = [System.Windows.Forms.DockStyle]::Fill
    $list.View = [System.Windows.Forms.View]::Details
    $list.FullRowSelect = $true
    $list.HideSelection = $false
    $list.Columns.Add((T "Path"), 500) | Out-Null
    $list.Columns.Add("JSONL", 70) | Out-Null
    $list.Columns.Add((T "LastWrite"), 150) | Out-Null
    $list.Columns.Add((T "Kind"), 110) | Out-Null
    foreach ($source in $sources) {
        $item = New-Object System.Windows.Forms.ListViewItem($source.Path)
        $item.SubItems.Add([string]$source.JsonlCount) | Out-Null
        $item.SubItems.Add($source.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")) | Out-Null
        $item.SubItems.Add($source.SourceKind) | Out-Null
        $item.Tag = $source
        $list.Items.Add($item) | Out-Null
    }
    if ($list.Items.Count -gt 0) { $list.Items[0].Selected = $true }
    $layout.Controls.Add($list, 0, 0)

    $buttons = New-Object System.Windows.Forms.FlowLayoutPanel
    $buttons.Dock = [System.Windows.Forms.DockStyle]::Fill
    $buttons.FlowDirection = [System.Windows.Forms.FlowDirection]::RightToLeft
    $buttons.Padding = New-Object System.Windows.Forms.Padding(8)
    $btnOk = New-Object System.Windows.Forms.Button
    $btnOk.Text = T "UseSelected"
    $btnOk.Width = 110
    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = T "Cancel"
    $btnCancel.Width = 90
    $buttons.Controls.Add($btnOk)
    $buttons.Controls.Add($btnCancel)
    $layout.Controls.Add($buttons, 0, 1)

    $btnOk.Add_Click({
        if ($list.SelectedItems.Count -gt 0) {
            $txtSourceSessions.Text = $list.SelectedItems[0].Tag.Path
            Add-Log (T "SourceSet" @($txtSourceSessions.Text))
            $picker.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $picker.Close()
        }
    })
    $btnCancel.Add_Click({ $picker.DialogResult = [System.Windows.Forms.DialogResult]::Cancel; $picker.Close() })
    $list.Add_DoubleClick({ $btnOk.PerformClick() })
    [void]$picker.ShowDialog($form)
    Add-Log (T "SourcesFound" @($sources.Count))
}

$form = New-Object System.Windows.Forms.Form
$form.Text = T "AppTitle"
$form.StartPosition = "CenterScreen"
$form.Size = New-Object System.Drawing.Size(1100, 720)
$form.MinimumSize = New-Object System.Drawing.Size(920, 620)
$form.Font = New-CHRFont 9

function New-CHRButton {
    param(
        [string] $Text,
        [int] $Width = 132,
        [int] $Height = 32,
        [System.Drawing.Color] $BackColor = [System.Drawing.SystemColors]::Control
    )
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $Text
    $button.Width = $Width
    $button.Height = $Height
    $button.Margin = New-Object System.Windows.Forms.Padding(0, 0, 8, 0)
    if ($BackColor -ne [System.Drawing.SystemColors]::Control) {
        $button.UseVisualStyleBackColor = $false
        $button.BackColor = $BackColor
    }
    return $button
}

function New-CHRLabel {
    param([string] $Text, [bool] $Bold = $false)
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Text
    $label.Dock = [System.Windows.Forms.DockStyle]::Fill
    $label.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    if ($Bold) { $label.Font = New-CHRFont 9 ([System.Drawing.FontStyle]::Bold) }
    return $label
}

$main = New-Object System.Windows.Forms.TableLayoutPanel
$main.Dock = [System.Windows.Forms.DockStyle]::Fill
$main.ColumnCount = 1
$main.RowCount = 6
$main.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 112))) | Out-Null
$main.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 92))) | Out-Null
$main.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 0))) | Out-Null
$main.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 44))) | Out-Null
$main.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
$main.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 0))) | Out-Null
$form.Controls.Add($main)

$hero = New-Object System.Windows.Forms.TableLayoutPanel
$hero.Dock = [System.Windows.Forms.DockStyle]::Fill
$hero.Padding = New-Object System.Windows.Forms.Padding(18, 10, 18, 8)
$hero.BackColor = [System.Drawing.Color]::FromArgb(246, 248, 252)
$hero.ColumnCount = 2
$hero.RowCount = 3
$hero.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 64))) | Out-Null
$hero.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 36))) | Out-Null
$hero.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 30))) | Out-Null
$hero.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 26))) | Out-Null
$hero.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
$main.Controls.Add($hero, 0, 0)

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = T "HeroTitle"
$lblTitle.Dock = [System.Windows.Forms.DockStyle]::Fill
$lblTitle.Font = New-CHRFont 14 ([System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = [System.Drawing.Color]::FromArgb(28, 42, 62)
$hero.Controls.Add($lblTitle, 0, 0)

$lblSubTitle = New-Object System.Windows.Forms.Label
$lblSubTitle.Text = T "HeroSubtitle"
$lblSubTitle.Dock = [System.Windows.Forms.DockStyle]::Fill
$lblSubTitle.ForeColor = [System.Drawing.Color]::FromArgb(74, 82, 94)
$hero.Controls.Add($lblSubTitle, 0, 1)

$lblNextStep = New-Object System.Windows.Forms.Label
$lblNextStep.Text = T "NextChooseProject"
$lblNextStep.Dock = [System.Windows.Forms.DockStyle]::Fill
$lblNextStep.Font = New-CHRFont 10 ([System.Drawing.FontStyle]::Bold)
$lblNextStep.ForeColor = [System.Drawing.Color]::FromArgb(40, 92, 150)
$hero.Controls.Add($lblNextStep, 0, 2)

$statusPanel = New-Object System.Windows.Forms.TableLayoutPanel
$statusPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$statusPanel.ColumnCount = 1
$statusPanel.RowCount = 4
$statusPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 20))) | Out-Null
$statusPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 20))) | Out-Null
$statusPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 20))) | Out-Null
$statusPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 20))) | Out-Null
$hero.Controls.Add($statusPanel, 1, 0)
$hero.SetRowSpan($statusPanel, 3)

$lblEnvStatus = New-CHRLabel (T "EnvChecking")
$lblProjectStatus = New-CHRLabel (T "ProjectNotSelected")
$lblRowsStatus = New-CHRLabel (T "RecordsNotLoaded")
$lblSelectedStatus = New-CHRLabel (T "SelectedCount" @(0))
$statusPanel.Controls.Add($lblEnvStatus, 0, 0)
$statusPanel.Controls.Add($lblProjectStatus, 0, 1)
$statusPanel.Controls.Add($lblRowsStatus, 0, 2)
$statusPanel.Controls.Add($lblSelectedStatus, 0, 3)

$restorePanel = New-Object System.Windows.Forms.TableLayoutPanel
$restorePanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$restorePanel.Padding = New-Object System.Windows.Forms.Padding(18, 12, 18, 12)
$restorePanel.ColumnCount = 4
$restorePanel.RowCount = 2
$restorePanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 132))) | Out-Null
$restorePanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
$restorePanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 142))) | Out-Null
$restorePanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 142))) | Out-Null
$restorePanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 34))) | Out-Null
$restorePanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
$main.Controls.Add($restorePanel, 0, 1)

$lblSimpleHelp = New-Object System.Windows.Forms.Label
$lblSimpleHelp.Text = T "SimpleHelp"
$lblSimpleHelp.Dock = [System.Windows.Forms.DockStyle]::Fill
$lblSimpleHelp.ForeColor = [System.Drawing.Color]::FromArgb(82, 88, 96)
$restorePanel.Controls.Add($lblSimpleHelp, 0, 0)
$restorePanel.SetColumnSpan($lblSimpleHelp, 4)

$primaryActions = New-Object System.Windows.Forms.FlowLayoutPanel
$primaryActions.Dock = [System.Windows.Forms.DockStyle]::Fill
$primaryActions.WrapContents = $false
$restorePanel.Controls.Add($primaryActions, 0, 1)
$restorePanel.SetColumnSpan($primaryActions, 4)

$btnLoad = New-CHRButton (T "LoadRecords") 168 34
$btnSelectOld = New-CHRButton (T "SelectHidden") 132 34
$btnDryRun = New-CHRButton (T "Preview") 132 34 ([System.Drawing.Color]::FromArgb(224, 237, 252))
$btnDryRun.Visible = $false
$btnRestore = New-CHRButton (T "RestoreSelected") 150 34 ([System.Drawing.Color]::FromArgb(218, 242, 225))
$btnMoreTools = New-CHRButton (T "MoreTools") 124 34
foreach ($button in @($btnLoad, $btnSelectOld, $btnRestore, $btnMoreTools)) { $primaryActions.Controls.Add($button) }

$advancedPanel = New-Object System.Windows.Forms.TableLayoutPanel
$advancedPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$advancedPanel.Padding = New-Object System.Windows.Forms.Padding(18, 8, 18, 8)
$advancedPanel.ColumnCount = 4
$advancedPanel.RowCount = 8
$advancedPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 132))) | Out-Null
$advancedPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
$advancedPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 132))) | Out-Null
$advancedPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 132))) | Out-Null
foreach ($height in @(24, 32, 32, 24, 32, 24, 32, 32)) {
    $advancedPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, $height))) | Out-Null
}
$advancedPanel.Visible = $false
$main.Controls.Add($advancedPanel, 0, 2)

$lblDataLocations = New-CHRLabel (T "DataLocations") $true
$advancedPanel.Controls.Add($lblDataLocations, 0, 0)
$advancedPanel.SetColumnSpan($lblDataLocations, 4)

$txtCodexHome = New-Object System.Windows.Forms.TextBox
$txtCodexHome.Text = Get-CHRDefaultCodexHome
$txtCodexHome.Dock = [System.Windows.Forms.DockStyle]::Fill
$btnDetect = New-CHRButton (T "ReCheck") 122 26
$lblCodexHome = New-CHRLabel (T "CodexHome")
$advancedPanel.Controls.Add($lblCodexHome, 0, 1)
$advancedPanel.Controls.Add($txtCodexHome, 1, 1)
$advancedPanel.Controls.Add($btnDetect, 2, 1)

$txtSourceSessions = New-Object System.Windows.Forms.TextBox
$txtSourceSessions.Dock = [System.Windows.Forms.DockStyle]::Fill
$btnBrowseSource = New-CHRButton (T "Browse") 122 26
$btnFindSources = New-CHRButton (T "FindSources") 122 26
$lblImportSource = New-CHRLabel (T "ImportSource")
$advancedPanel.Controls.Add($lblImportSource, 0, 2)
$advancedPanel.Controls.Add($txtSourceSessions, 1, 2)
$advancedPanel.Controls.Add($btnBrowseSource, 2, 2)
$advancedPanel.Controls.Add($btnFindSources, 3, 2)

$lblSafetyRollback = New-CHRLabel (T "SafetyRollback") $true
$advancedPanel.Controls.Add($lblSafetyRollback, 0, 3)
$advancedPanel.SetColumnSpan($lblSafetyRollback, 4)

$txtBackupRoot = New-Object System.Windows.Forms.TextBox
$txtBackupRoot.Text = Get-CHRDefaultBackupRoot
$txtBackupRoot.Dock = [System.Windows.Forms.DockStyle]::Fill
$btnBrowseBackup = New-CHRButton (T "Browse") 122 26
$btnBackups = New-CHRButton (T "Rollback") 122 26
$lblBackupFolder = New-CHRLabel (T "BackupFolder")
$advancedPanel.Controls.Add($lblBackupFolder, 0, 4)
$advancedPanel.Controls.Add($txtBackupRoot, 1, 4)
$advancedPanel.Controls.Add($btnBrowseBackup, 2, 4)
$advancedPanel.Controls.Add($btnBackups, 3, 4)

$lblExpertOptions = New-CHRLabel (T "ExpertOptions") $true
$advancedPanel.Controls.Add($lblExpertOptions, 0, 5)
$advancedPanel.SetColumnSpan($lblExpertOptions, 4)

$txtProjectRoot = New-Object System.Windows.Forms.TextBox
$txtProjectRoot.Dock = [System.Windows.Forms.DockStyle]::Fill
$btnChooseProjectAction = New-CHRButton (T "ChooseProject") 122 26
$btnBrowseProject = New-CHRButton (T "BrowseFolder") 122 26
$lblRestoreInto = New-CHRLabel (T "RestoreInto")
$advancedPanel.Controls.Add($lblRestoreInto, 0, 6)
$advancedPanel.Controls.Add($txtProjectRoot, 1, 6)
$advancedPanel.Controls.Add($btnChooseProjectAction, 2, 6)
$advancedPanel.Controls.Add($btnBrowseProject, 3, 6)

$txtTemplateThreadId = New-Object System.Windows.Forms.TextBox
$txtTemplateThreadId.Dock = [System.Windows.Forms.DockStyle]::Fill
$chkOnlyOld = New-Object System.Windows.Forms.CheckBox
$chkOnlyOld.Text = T "HiddenOnly"
$chkOnlyOld.Dock = [System.Windows.Forms.DockStyle]::Fill
$chkNoTouch = New-Object System.Windows.Forms.CheckBox
$chkNoTouch.Text = T "DoNotBump"
$chkNoTouch.Dock = [System.Windows.Forms.DockStyle]::Fill
$lblTemplateThread = New-CHRLabel (T "TemplateThread")
$advancedPanel.Controls.Add($lblTemplateThread, 0, 7)
$advancedPanel.Controls.Add($txtTemplateThreadId, 1, 7)
$advancedPanel.Controls.Add($chkOnlyOld, 2, 7)
$advancedPanel.Controls.Add($chkNoTouch, 3, 7)

$btnImport = New-CHRButton (T "ImportSessions") 122 26
$btnDetectAction = New-Object System.Windows.Forms.Button
$btnChooseProject = New-Object System.Windows.Forms.Button
$btnFindSourcesAction = New-Object System.Windows.Forms.Button
$btnClearSelection = New-CHRButton (T "ClearSelection") 116 28

$filterBar = New-Object System.Windows.Forms.TableLayoutPanel
$filterBar.Dock = [System.Windows.Forms.DockStyle]::Fill
$filterBar.Padding = New-Object System.Windows.Forms.Padding(18, 6, 18, 4)
$filterBar.ColumnCount = 6
$filterBar.RowCount = 1
$filterBar.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 60))) | Out-Null
$filterBar.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 260))) | Out-Null
$filterBar.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 110))) | Out-Null
$filterBar.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
$filterBar.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 72))) | Out-Null
$filterBar.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 130))) | Out-Null
$main.Controls.Add($filterBar, 0, 3)

$lblSearch = New-CHRLabel (T "Search")
$filterBar.Controls.Add($lblSearch, 0, 0)
$txtSearch = New-Object System.Windows.Forms.TextBox
$txtSearch.Dock = [System.Windows.Forms.DockStyle]::Fill
$filterBar.Controls.Add($txtSearch, 1, 0)
$cmbStatusFilter = New-Object System.Windows.Forms.ComboBox
$cmbStatusFilter.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$cmbStatusFilter.Dock = [System.Windows.Forms.DockStyle]::Fill
[void]$cmbStatusFilter.Items.Add((T "All"))
[void]$cmbStatusFilter.Items.Add((T "Hidden"))
[void]$cmbStatusFilter.Items.Add((T "Visible"))
$cmbStatusFilter.SelectedItem = T "All"
$filterBar.Controls.Add($cmbStatusFilter, 2, 0)
$btnShowLog = New-CHRButton (T "ShowLog") 116 28
$lblLanguage = New-CHRLabel (T "Language")
$filterBar.Controls.Add($lblLanguage, 4, 0)
$cmbLanguage = New-Object System.Windows.Forms.ComboBox
$cmbLanguage.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$cmbLanguage.Dock = [System.Windows.Forms.DockStyle]::Fill
[void]$cmbLanguage.Items.Add("English")
[void]$cmbLanguage.Items.Add("中文")
$cmbLanguage.SelectedItem = if ($script:Language -eq "zh") { "中文" } else { "English" }
$filterBar.Controls.Add($cmbLanguage, 5, 0)

$toolTip = New-Object System.Windows.Forms.ToolTip
$toolTip.AutoPopDelay = 12000
$toolTip.InitialDelay = 400
$toolTip.ReshowDelay = 100
$toolTip.SetToolTip($txtProjectRoot, (T "ToolTipProject"))
$toolTip.SetToolTip($btnLoad, (T "ToolTipLoad"))
$toolTip.SetToolTip($btnSelectOld, (T "ToolTipSelect"))
$toolTip.SetToolTip($btnDryRun, (T "ToolTipPreview"))
$toolTip.SetToolTip($btnRestore, (T "ToolTipRestore"))
$toolTip.SetToolTip($btnMoreTools, (T "ToolTipMore"))
$toolTip.SetToolTip($txtCodexHome, (T "ToolTipCodexHome"))
$toolTip.SetToolTip($txtSourceSessions, (T "ToolTipSource"))
$toolTip.SetToolTip($txtBackupRoot, (T "ToolTipBackup"))
$toolTip.SetToolTip($txtTemplateThreadId, (T "ToolTipTemplate"))
$toolTip.SetToolTip($chkOnlyOld, (T "ToolTipHiddenOnly"))
$toolTip.SetToolTip($chkNoTouch, (T "ToolTipNoTouch"))

$gridPanel = New-Object System.Windows.Forms.Panel
$gridPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$main.Controls.Add($gridPanel, 0, 4)

$grid = New-Object System.Windows.Forms.DataGridView
$grid.Dock = [System.Windows.Forms.DockStyle]::Fill
$grid.AllowUserToAddRows = $false
$grid.AllowUserToDeleteRows = $false
$grid.AllowUserToResizeRows = $false
$grid.SelectionMode = [System.Windows.Forms.DataGridViewSelectionMode]::FullRowSelect
$grid.MultiSelect = $true
$grid.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
$grid.RowHeadersVisible = $false
$grid.BackgroundColor = [System.Drawing.Color]::White
$grid.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$gridPanel.Controls.Add($grid)

$colSelected = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn
$colSelected.Name = "Selected"
$colSelected.HeaderText = ""
$colSelected.Width = 36
$colSelected.FillWeight = 8
$grid.Columns.Add($colSelected) | Out-Null
foreach ($col in @(
    @{Name="Number"; Header="#"; Weight=10},
    @{Name="Status"; Header=(T "Status"); Weight=14},
    @{Name="Title"; Header=(T "Title"); Weight=80},
    @{Name="ThreadId"; Header=(T "ThreadId"); Weight=48},
    @{Name="UpdatedAt"; Header=(T "Updated"); Weight=34},
    @{Name="Project"; Header=(T "Project"); Weight=58}
)) {
    $c = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $c.Name = $col.Name
    $c.HeaderText = $col.Header
    $c.ReadOnly = $true
    $c.FillWeight = $col.Weight
    $grid.Columns.Add($c) | Out-Null
}

$lblEmptyStateTitle = New-Object System.Windows.Forms.Label
$lblEmptyStateTitle.AutoSize = $false
$lblEmptyStateTitle.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$lblEmptyStateTitle.Font = New-CHRFont 12 ([System.Drawing.FontStyle]::Bold)
$lblEmptyStateTitle.ForeColor = [System.Drawing.Color]::FromArgb(74, 82, 94)
$lblEmptyStateTitle.Dock = [System.Windows.Forms.DockStyle]::Fill
$lblEmptyStateTitle.BackColor = [System.Drawing.Color]::White
$lblEmptyStateBody = New-Object System.Windows.Forms.Label
$lblEmptyStateBody.AutoSize = $false
$lblEmptyStateBody.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$lblEmptyStateBody.Font = New-CHRFont 9
$lblEmptyStateBody.ForeColor = [System.Drawing.Color]::FromArgb(96, 104, 116)
$lblEmptyStateBody.Dock = [System.Windows.Forms.DockStyle]::Fill
$lblEmptyStateBody.Padding = New-Object System.Windows.Forms.Padding(0, 54, 0, 0)
$lblEmptyStateBody.BackColor = [System.Drawing.Color]::White
$gridPanel.Controls.Add($lblEmptyStateBody)
$gridPanel.Controls.Add($lblEmptyStateTitle)
$lblEmptyStateTitle.BringToFront()
$lblEmptyStateBody.BringToFront()

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Dock = [System.Windows.Forms.DockStyle]::Fill
$txtLog.Multiline = $true
$txtLog.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$txtLog.ReadOnly = $true
$txtLog.Font = New-Object System.Drawing.Font("Consolas", 9)
$txtLog.Visible = $false
$main.Controls.Add($txtLog, 0, 5)

function Apply-CHRLanguage {
    $script:ApplyingLanguage = $true
    try {
        $statusKey = ""
        if ($cmbStatusFilter -and $cmbStatusFilter.SelectedItem) {
            $statusKey = Get-CHRStatusKeyFromDisplay ([string]$cmbStatusFilter.SelectedItem)
        }

        $form.Text = T "AppTitle"
        $lblTitle.Text = T "HeroTitle"
        $lblSubTitle.Text = T "HeroSubtitle"
        $lblLanguage.Text = T "Language"
        $lblRestoreInto.Text = T "RestoreInto"
        $lblSimpleHelp.Text = T "SimpleHelp"
        $lblCodexHome.Text = T "CodexHome"
        $lblImportSource.Text = T "ImportSource"
        $lblBackupFolder.Text = T "BackupFolder"
        $lblTemplateThread.Text = T "TemplateThread"
        $lblSearch.Text = T "Search"
        $lblDataLocations.Text = T "DataLocations"
        $lblSafetyRollback.Text = T "SafetyRollback"
        $lblExpertOptions.Text = T "ExpertOptions"

        $btnChooseProjectAction.Text = T "ChooseProject"
        $btnBrowseProject.Text = T "BrowseFolder"
        $btnLoad.Text = T "LoadRecords"
        $btnSelectOld.Text = T "SelectHidden"
        $btnDryRun.Text = T "Preview"
        $btnRestore.Text = T "RestoreSelected"
        $btnMoreTools.Text = T "MoreTools"
        $btnDetect.Text = T "ReCheck"
        $btnBrowseSource.Text = T "Browse"
        $btnFindSources.Text = T "FindSources"
        $btnBrowseBackup.Text = T "Browse"
        $btnBackups.Text = T "Rollback"
        $btnImport.Text = T "ImportSessions"
        $btnClearSelection.Text = T "ClearSelection"
        $btnShowLog.Text = if ($txtLog.Visible) { T "HideLog" } else { T "ShowLog" }
        $chkOnlyOld.Text = T "HiddenOnly"
        $chkNoTouch.Text = T "DoNotBump"

        $cmbStatusFilter.Items.Clear()
        [void]$cmbStatusFilter.Items.Add((T "All"))
        [void]$cmbStatusFilter.Items.Add((T "Hidden"))
        [void]$cmbStatusFilter.Items.Add((T "Visible"))
        $cmbStatusFilter.SelectedItem = switch ($statusKey) {
            "old" { T "Hidden" }
            "desktop" { T "Visible" }
            default { T "All" }
        }

        $grid.Columns["Number"].HeaderText = "#"
        $grid.Columns["Status"].HeaderText = T "Status"
        $grid.Columns["Title"].HeaderText = T "Title"
        $grid.Columns["ThreadId"].HeaderText = T "ThreadId"
        $grid.Columns["UpdatedAt"].HeaderText = T "Updated"
        $grid.Columns["Project"].HeaderText = T "Project"

        $menuFind.Text = T "ScanOtherSources"
        $menuAdvanced.Text = if ($advancedPanel.Visible) { T "HideAdvanced" } else { T "ShowAdvanced" }
        $menuLog.Text = if ($txtLog.Visible) { T "HideLog" } else { T "ShowLog" }
        $menuRollback.Text = T "BackupsRollback"
        $menuDetect.Text = T "ReCheckEnvironment"

        $toolTip.SetToolTip($txtProjectRoot, (T "ToolTipProject"))
        $toolTip.SetToolTip($btnLoad, (T "ToolTipLoad"))
        $toolTip.SetToolTip($btnSelectOld, (T "ToolTipSelect"))
        $toolTip.SetToolTip($btnDryRun, (T "ToolTipPreview"))
        $toolTip.SetToolTip($btnRestore, (T "ToolTipRestore"))
        $toolTip.SetToolTip($btnMoreTools, (T "ToolTipMore"))
        $toolTip.SetToolTip($txtCodexHome, (T "ToolTipCodexHome"))
        $toolTip.SetToolTip($txtSourceSessions, (T "ToolTipSource"))
        $toolTip.SetToolTip($txtBackupRoot, (T "ToolTipBackup"))
        $toolTip.SetToolTip($txtTemplateThreadId, (T "ToolTipTemplate"))
        $toolTip.SetToolTip($chkOnlyOld, (T "ToolTipHiddenOnly"))
        $toolTip.SetToolTip($chkNoTouch, (T "ToolTipNoTouch"))
    } finally {
        $script:ApplyingLanguage = $false
    }

    if ($script:Rows.Count -gt 0) { Apply-GridFilter } else { Update-EmptyState }
    Update-Guidance
}

$moreMenu = New-Object System.Windows.Forms.ContextMenuStrip
$menuFind = $moreMenu.Items.Add((T "ScanOtherSources"))
$menuRollback = $moreMenu.Items.Add((T "BackupsRollback"))
$moreMenu.Items.Add("-") | Out-Null
$menuAdvanced = $moreMenu.Items.Add((T "ShowAdvanced"))
$menuLog = $moreMenu.Items.Add((T "ShowLog"))
$menuDetect = $moreMenu.Items.Add((T "ReCheckEnvironment"))
$btnMoreTools.Add_Click({ $moreMenu.Show($btnMoreTools, 0, $btnMoreTools.Height) })
$menuAdvanced.Add_Click({
    $advancedPanel.Visible = -not $advancedPanel.Visible
    $main.RowStyles[2].Height = if ($advancedPanel.Visible) { 264 } else { 0 }
    $menuAdvanced.Text = if ($advancedPanel.Visible) { T "HideAdvanced" } else { T "ShowAdvanced" }
})
$menuLog.Add_Click({
    $txtLog.Visible = -not $txtLog.Visible
    $main.RowStyles[5].Height = if ($txtLog.Visible) { 118 } else { 0 }
    $menuLog.Text = if ($txtLog.Visible) { T "HideLog" } else { T "ShowLog" }
})
$menuFind.Add_Click({ Invoke-Safe { Invoke-FindRecoverableRecords } })
$menuRollback.Add_Click({ Invoke-Safe { Invoke-Backups } })
$menuDetect.Add_Click({ Invoke-Safe { Invoke-Detect } })

$btnDetect.Add_Click({ Invoke-Safe { Invoke-Detect } })
$btnDetectAction.Add_Click({ Invoke-Safe { Invoke-Detect } })
$btnBrowseProject.Add_Click({ $path = Select-Folder (T "SelectProjectFolder") $txtProjectRoot.Text; if ($path) { $txtProjectRoot.Text = $path; Update-Guidance } })
$btnChooseProject.Add_Click({ Invoke-Safe { Invoke-ChooseProject } })
$btnChooseProjectAction.Add_Click({ Invoke-Safe { Invoke-ChooseProject } })
$btnBrowseSource.Add_Click({ $path = Select-Folder (T "SelectSourceFolder") $txtSourceSessions.Text; if ($path) { $txtSourceSessions.Text = $path; Update-Guidance (T "SourceSelectedHint") } })
$btnFindSources.Add_Click({ Invoke-Safe { Invoke-FindSources } })
$btnFindSourcesAction.Add_Click({ Invoke-Safe { Invoke-FindSources } })
$btnBrowseBackup.Add_Click({ $path = Select-Folder (T "SelectBackupFolder") $txtBackupRoot.Text; if ($path) { $txtBackupRoot.Text = $path; Update-Guidance } })
$btnLoad.Add_Click({ Invoke-Safe { Invoke-FindRecoverableRecords } })
$btnSelectOld.Add_Click({ Select-OldRows })
$btnClearSelection.Add_Click({ Clear-SelectedRows })
$btnDryRun.Add_Click({ Invoke-Safe { Invoke-DryRun } })
$btnRestore.Add_Click({ Invoke-Safe { Invoke-RestoreSelected } })
$btnImport.Add_Click({ Invoke-Safe { Invoke-ImportSessions } })
$btnBackups.Add_Click({ Invoke-Safe { Invoke-Backups } })
$txtSearch.Add_TextChanged({ Apply-GridFilter })
$cmbStatusFilter.Add_SelectedIndexChanged({ if (-not $script:ApplyingLanguage) { Apply-GridFilter } })
$cmbLanguage.Add_SelectedIndexChanged({
    $script:Language = if ([string]$cmbLanguage.SelectedItem -eq "中文") { "zh" } else { "en" }
    Apply-CHRLanguage
})
$grid.Add_CurrentCellDirtyStateChanged({ if ($grid.IsCurrentCellDirty) { $grid.CommitEdit([System.Windows.Forms.DataGridViewDataErrorContexts]::Commit) | Out-Null } })
$grid.Add_CellValueChanged({ Update-Guidance })
$grid.Add_CellDoubleClick({ Show-ThreadDetails })

$form.Add_Shown({ Apply-CHRLanguage; Invoke-Safe { Invoke-Detect } })

[void][System.Windows.Forms.Application]::Run($form)

