$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "CodexHistoryRestorer.Core.psm1") -Force -DisableNameChecking

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

$script:Rows = @()
$script:LastEnvironment = $null

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
    Add-Log "ERROR: $Message"
    [System.Windows.Forms.MessageBox]::Show($Message, "Codex History Restorer", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
}

function Set-Busy {
    param([bool] $Busy)
    $form.Cursor = if ($Busy) { [System.Windows.Forms.Cursors]::WaitCursor } else { [System.Windows.Forms.Cursors]::Default }
    foreach ($control in @($btnDetect, $btnDetectAction, $btnBrowseProject, $btnChooseProject, $btnChooseProjectAction, $btnBrowseSource, $btnFindSources, $btnFindSourcesAction, $btnBrowseBackup, $btnLoad, $btnImport, $btnDryRun, $btnRestore, $btnSelectOld, $btnClearSelection, $btnBackups, $btnMoreTools, $btnShowLog, $txtSearch, $cmbStatusFilter)) {
        if (-not $control) { continue }
        $control.Enabled = -not $Busy
    }
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

function Invoke-Detect {
    $envInfo = Test-CHREnvironment -CodexHome $txtCodexHome.Text
    $script:LastEnvironment = $envInfo
    if ($envInfo.Ok) {
        Add-Log "Environment OK."
    } else {
        Add-Log "Environment has issues."
        foreach ($err in $envInfo.Errors) { Add-Log " - $err" }
    }
    Add-Log "Codex home: $($envInfo.CodexHome)"
    Add-Log "Database: $($envInfo.Database)"
    if ($envInfo.SqlitePath) { Add-Log "sqlite3: $($envInfo.SqlitePath)" }
    if ($envInfo.TemplateThreadId) { Add-Log "Template thread: $($envInfo.TemplateThreadId)" }
    if ($envInfo.DesktopRunning) {
        Add-Log "Warning: Codex Desktop appears to be running. Close it before large imports when possible."
    }
    Update-Guidance
}

function Load-Threads {
    $db = Get-DbPathFromUi
    if (-not (Test-Path -LiteralPath $db)) { throw "Codex database not found: $db" }
    $projectDbCwd = Get-ProjectDbCwdFromUi
    $template = Get-TemplateFromUi
    $script:Rows = @(Get-CHRThreadRows -Database $db -ProjectDbCwd $projectDbCwd -CurrentModelProvider $template.ModelProvider -OldOnly:$chkOnlyOld.Checked)
    Apply-GridFilter
    Add-Log "Loaded $($script:Rows.Count) thread(s). Current provider: $($template.ModelProvider)"
    Update-Guidance
}

function Apply-GridFilter {
    $query = $txtSearch.Text.Trim()
    $status = [string]$cmbStatusFilter.SelectedItem
    $statusKey = switch ($status) {
        "Hidden" { "old" }
        "Visible" { "desktop" }
        default { "" }
    }
    $grid.Rows.Clear()
    $displayRows = @($script:Rows | Where-Object {
        $matchStatus = ($status -eq "All" -or [string]::IsNullOrWhiteSpace($statusKey) -or $_.Status -eq $statusKey)
        $matchText = (-not $query) -or ($_.Title -like "*$query*") -or ($_.Id -like "*$query*") -or ($_.Cwd -like "*$query*")
        $matchStatus -and $matchText
    })
    foreach ($row in $displayRows) {
        $idx = $grid.Rows.Add()
        $grid.Rows[$idx].Cells["Selected"].Value = $false
        $grid.Rows[$idx].Cells["Number"].Value = $row.Number
        $grid.Rows[$idx].Cells["Status"].Value = if ($row.Status -eq "old") { "Hidden" } else { "Visible" }
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
    Add-Log "Showing $($displayRows.Count) of $($script:Rows.Count) thread(s)."
    Update-Guidance
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
        $gridRow.Cells["Selected"].Value = ([string]$gridRow.Cells["Status"].Value -eq "Hidden")
    }
    Add-Log "Selected all hidden rows."
    Update-Guidance
}

function Clear-SelectedRows {
    foreach ($gridRow in $grid.Rows) {
        if ($gridRow.IsNewRow) { continue }
        $gridRow.Cells["Selected"].Value = $false
    }
    Add-Log "Selection cleared."
    Update-Guidance
}

function Update-Guidance {
    param([string] $Hint = "")

    if (-not (Get-Variable -Name lblNextStep -ErrorAction SilentlyContinue)) { return }

    $envText = "Environment: not checked"
    $envColor = [System.Drawing.Color]::FromArgb(96, 96, 96)
    if ($script:LastEnvironment) {
        if ($script:LastEnvironment.Ok) {
            $envText = "Environment: ready"
            $envColor = [System.Drawing.Color]::FromArgb(23, 118, 72)
        } else {
            $envText = "Environment: needs attention"
            $envColor = [System.Drawing.Color]::FromArgb(180, 72, 28)
        }
    }

    $projectText = if ([string]::IsNullOrWhiteSpace($txtProjectRoot.Text)) { "Project: not selected" } else { "Project: " + $txtProjectRoot.Text }
    $rowText = if ($script:Rows.Count -gt 0) {
        $oldCount = @($script:Rows | Where-Object { $_.Status -eq "old" }).Count
        "Records: $($script:Rows.Count) loaded, $oldCount hidden"
    } else {
        "Records: not loaded"
    }
    $selectedCount = 0
    if ((Get-Variable -Name grid -ErrorAction SilentlyContinue) -and $grid.Columns.Count -gt 0) {
        foreach ($gridRow in $grid.Rows) {
            if ($gridRow.IsNewRow) { continue }
            if ([bool]$gridRow.Cells["Selected"].Value) { $selectedCount++ }
        }
    }
    $selectionText = "Selected: $selectedCount"

    if ($Hint) {
        $next = $Hint
    } elseif (-not $script:LastEnvironment -or -not $script:LastEnvironment.Ok) {
        $next = "Next: use More tools > Re-check environment. If sqlite3 is missing, put sqlite3.exe in the tools folder or install it in PATH."
    } elseif ([string]::IsNullOrWhiteSpace($txtProjectRoot.Text)) {
        $next = "Next: click Choose project, then pick the project whose chats you want to restore."
    } elseif ($script:Rows.Count -eq 0) {
        $next = "Next: click Load records. The table will show hidden chats and already-visible chats."
    } elseif ($selectedCount -eq 0) {
        $next = "Next: click Select hidden, or tick rows manually. Hidden rows are usually the ones to restore."
    } else {
        $next = "Next: click Preview first. If it looks right, click Restore selected."
    }

    $lblNextStep.Text = $next
    $lblEnvStatus.Text = $envText
    $lblEnvStatus.ForeColor = $envColor
    $lblProjectStatus.Text = $projectText
    $lblRowsStatus.Text = $rowText
    $lblSelectedStatus.Text = $selectionText
}

function Get-TemplateFromUi {
    return Get-CHRTemplate -Database (Get-DbPathFromUi) -RequestedThreadId $txtTemplateThreadId.Text.Trim()
}

function Invoke-DryRun {
    $selected = Get-SelectedRowsFromGrid
    if ($selected.Count -eq 0) { throw "Select at least one thread first." }
    $template = Get-TemplateFromUi
    Add-Log "Dry run. No files will be changed."
    Add-Log "Template thread: $($template.Id)"
    Add-Log "Would restore $($selected.Count) thread(s):"
    foreach ($row in $selected) {
        Add-Log " - $($row.Id) $(Get-CHRShortTitle $row.Title 80)"
    }
    Update-Guidance "Preview complete. If the selected rows are correct, click Restore selected."
}

function Invoke-RestoreSelected {
    $selected = Get-SelectedRowsFromGrid
    if ($selected.Count -eq 0) { throw "Select at least one thread first." }
    if ((Get-CHRDesktopProcesses).Count -gt 0) {
        $running = [System.Windows.Forms.MessageBox]::Show("Codex Desktop appears to be running. Continue anyway?`n`nFor large imports/restores, closing Codex first is safer.", "Codex is running", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($running -ne [System.Windows.Forms.DialogResult]::Yes) { Add-Log "Restore cancelled."; return }
    }
    $message = "Restore $($selected.Count) selected thread(s)?`n`nA backup will be created in:`n$($txtBackupRoot.Text)"
    $confirm = [System.Windows.Forms.MessageBox]::Show($message, "Confirm restore", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) {
        Add-Log "Restore cancelled."
        return
    }
    $db = Get-DbPathFromUi
    $template = Get-TemplateFromUi
    $paths = Get-CHRRolloutPaths -Database $db -Rows $selected
    $backup = New-CHRBackup -Database $db -JsonlPaths $paths -BackupRoot $txtBackupRoot.Text -Operation "restore" -CodexHome $txtCodexHome.Text -ProjectRoot (Get-ProjectJsonCwdFromUi) -Rows $selected
    Add-Log "Backup created: $backup"
    Invoke-CHRSqlite -Database $db -Sql "pragma wal_checkpoint(full);" | Out-Null
    $changed = Repair-CHRThreads -Database $db -Rows $selected -ProjectDbCwd (Get-ProjectDbCwdFromUi) -ProjectJsonCwd (Get-ProjectJsonCwdFromUi) -Template $template -NoTouch:$chkNoTouch.Checked
    $sync = Sync-CHRSidebarState -Database $db -CodexHome $txtCodexHome.Text -CurrentModelProvider $template.ModelProvider
    Add-Log "Sidebar index synced: threads=$($sync.ThreadCount), provider=$($sync.ModelProvider)"
    Add-Log "Restored $(@($changed).Count) thread(s)."
    Load-Threads
    Update-Guidance "Restore complete. Open or refresh Codex Desktop and check the selected project."
}

function Invoke-ImportSessions {
    if ([string]::IsNullOrWhiteSpace($txtSourceSessions.Text)) { throw "Choose an external sessions folder first." }
    $db = Get-DbPathFromUi
    $template = Get-TemplateFromUi
    $scan = Test-CHRImportSessions -Database $db -SessionsDir $txtSourceSessions.Text
    Add-Log "Import scan: scanned=$($scan.Scanned) importable=$($scan.Importable) existing=$($scan.Existing) invalid=$($scan.Invalid)"
    if ($scan.Importable -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No importable sessions found.`n`nScanned: $($scan.Scanned)`nExisting: $($scan.Existing)`nInvalid: $($scan.Invalid)", "Import Sessions", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
        return
    }
    if ((Get-CHRDesktopProcesses).Count -gt 0) {
        $running = [System.Windows.Forms.MessageBox]::Show("Codex Desktop appears to be running. Continue anyway?`n`nFor imports, closing Codex first is safer.", "Codex is running", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($running -ne [System.Windows.Forms.DialogResult]::Yes) { Add-Log "Import cancelled."; return }
    }
    $message = "Import rollout-*.jsonl from:`n$($txtSourceSessions.Text)`n`nScanned: $($scan.Scanned)`nImportable: $($scan.Importable)`nExisting: $($scan.Existing)`nInvalid: $($scan.Invalid)`n`nNew rows will be inserted into the current Codex database."
    $confirm = [System.Windows.Forms.MessageBox]::Show($message, "Confirm import", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) {
        Add-Log "Import cancelled."
        return
    }
    $backup = New-CHRBackup -Database $db -JsonlPaths @() -BackupRoot $txtBackupRoot.Text -Operation "import" -CodexHome $txtCodexHome.Text -ProjectRoot (Get-ProjectJsonCwdFromUi)
    Add-Log "Database backup created: $backup"
    $result = Import-CHRJsonlSessions -Database $db -CodexHome $txtCodexHome.Text -SessionsDir $txtSourceSessions.Text -ProjectDbCwd (Get-ProjectDbCwdFromUi) -ProjectJsonCwd (Get-ProjectJsonCwdFromUi) -Template $template
    $sync = Sync-CHRSidebarState -Database $db -CodexHome $txtCodexHome.Text -CurrentModelProvider $template.ModelProvider
    Add-Log "Sidebar index synced: threads=$($sync.ThreadCount), provider=$($sync.ModelProvider)"
    Add-Log "Scanned $($result.Scanned) JSONL file(s). Imported $(@($result.Imported).Count), existing=$($result.Existing), invalid=$($result.Invalid)."
    $chkOnlyOld.Checked = $true
    $cmbStatusFilter.SelectedItem = "Hidden"
    Load-Threads
    Update-Guidance "Import complete. Imported rows are now loaded; preview and restore the hidden rows next."
}

function Invoke-ChooseProject {
    $db = Get-DbPathFromUi
    if (-not (Test-Path -LiteralPath $db)) { throw "Codex database not found: $db" }
    $projects = @(Get-CHRProjects -Database $db)
    if ($projects.Count -eq 0) { throw "No projects found in database." }
    $picker = New-Object System.Windows.Forms.Form
    $picker.Text = "Choose Project Root"
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
    $list.Columns.Add("Project", 600) | Out-Null
    $list.Columns.Add("Threads", 90) | Out-Null
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
    $btnOk.Text = "Use Selected"
    $btnOk.Width = 110
    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Cancel"
    $btnCancel.Width = 90
    $buttons.Controls.Add($btnOk)
    $buttons.Controls.Add($btnCancel)
    $layout.Controls.Add($buttons, 0, 1)
    $btnOk.Add_Click({
        if ($list.SelectedItems.Count -gt 0) {
            $txtProjectRoot.Text = $list.SelectedItems[0].Tag.Path
            Add-Log "Project root set to: $($txtProjectRoot.Text)"
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
    $message = "Thread Id: $($row.Id)`r`nStatus: $($row.Status)`r`nUpdated: $($row.UpdatedAt)`r`nProject: $($row.Cwd -replace '^\\\\\\?\\','')`r`n`r`nTitle:`r`n$($row.Title)"
    [System.Windows.Forms.MessageBox]::Show($message, "Thread Details", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
}

function Invoke-Backups {
    $backups = @(Get-CHRBackups -BackupRoot $txtBackupRoot.Text)
    if ($backups.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No backups found under:`n$($txtBackupRoot.Text)", "Backups / Rollback", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
        return
    }
    $picker = New-Object System.Windows.Forms.Form
    $picker.Text = "Backups / Rollback"
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
    $list.Columns.Add("Created", 150) | Out-Null
    $list.Columns.Add("Operation", 90) | Out-Null
    $list.Columns.Add("Threads", 70) | Out-Null
    $list.Columns.Add("Manifest", 70) | Out-Null
    $list.Columns.Add("Path", 500) | Out-Null
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
    $btnRollback.Text = "Rollback Selected"
    $btnRollback.Width = 130
    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = "Close"
    $btnClose.Width = 90
    $buttons.Controls.Add($btnRollback)
    $buttons.Controls.Add($btnClose)
    $layout.Controls.Add($buttons, 0, 1)
    $btnRollback.Add_Click({
        if ($list.SelectedItems.Count -eq 0) { return }
        $backup = $list.SelectedItems[0].Tag
        $confirm = [System.Windows.Forms.MessageBox]::Show("Rollback from this backup?`n`n$($backup.Path)`n`nThis will overwrite current database/JSONL files listed in the manifest.", "Confirm rollback", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) { return }
        try {
            $result = Restore-CHRBackup -BackupPath $backup.Path
            Add-Log "Rollback restored $($result.Restored) file(s) from $($backup.Path)"
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
        Add-Log "No rollout-*.jsonl sources found."
        [System.Windows.Forms.MessageBox]::Show("No rollout-*.jsonl sources found in common locations.", "Find Sources", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
        return
    }

    $picker = New-Object System.Windows.Forms.Form
    $picker.Text = "Choose Source Sessions Folder"
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
    $list.Columns.Add("Path", 500) | Out-Null
    $list.Columns.Add("JSONL", 70) | Out-Null
    $list.Columns.Add("Last Write", 150) | Out-Null
    $list.Columns.Add("Kind", 110) | Out-Null
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
    $btnOk.Text = "Use Selected"
    $btnOk.Width = 110
    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Cancel"
    $btnCancel.Width = 90
    $buttons.Controls.Add($btnOk)
    $buttons.Controls.Add($btnCancel)
    $layout.Controls.Add($buttons, 0, 1)

    $btnOk.Add_Click({
        if ($list.SelectedItems.Count -gt 0) {
            $txtSourceSessions.Text = $list.SelectedItems[0].Tag.Path
            Add-Log "Source sessions set to: $($txtSourceSessions.Text)"
            $picker.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $picker.Close()
        }
    })
    $btnCancel.Add_Click({ $picker.DialogResult = [System.Windows.Forms.DialogResult]::Cancel; $picker.Close() })
    $list.Add_DoubleClick({ $btnOk.PerformClick() })
    [void]$picker.ShowDialog($form)
    Add-Log "Found $($sources.Count) source candidate(s)."
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "Codex History Restorer"
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
$main.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 90))) | Out-Null
$main.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 142))) | Out-Null
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
$hero.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 26))) | Out-Null
$hero.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 22))) | Out-Null
$hero.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
$main.Controls.Add($hero, 0, 0)

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "Restore hidden Codex chats"
$lblTitle.Dock = [System.Windows.Forms.DockStyle]::Fill
$lblTitle.Font = New-CHRFont 14 ([System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = [System.Drawing.Color]::FromArgb(28, 42, 62)
$hero.Controls.Add($lblTitle, 0, 0)

$lblSubTitle = New-Object System.Windows.Forms.Label
$lblSubTitle.Text = "Pick a project, load hidden chats, preview, then restore. Nothing is changed until the final restore."
$lblSubTitle.Dock = [System.Windows.Forms.DockStyle]::Fill
$lblSubTitle.ForeColor = [System.Drawing.Color]::FromArgb(74, 82, 94)
$hero.Controls.Add($lblSubTitle, 0, 1)

$lblNextStep = New-Object System.Windows.Forms.Label
$lblNextStep.Text = "Next: choose a project."
$lblNextStep.Dock = [System.Windows.Forms.DockStyle]::Fill
$lblNextStep.Font = New-CHRFont 10 ([System.Drawing.FontStyle]::Bold)
$lblNextStep.ForeColor = [System.Drawing.Color]::FromArgb(40, 92, 150)
$hero.Controls.Add($lblNextStep, 0, 2)

$statusPanel = New-Object System.Windows.Forms.TableLayoutPanel
$statusPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$statusPanel.ColumnCount = 1
$statusPanel.RowCount = 4
for ($i = 0; $i -lt 4; $i++) { $statusPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 25))) | Out-Null }
$hero.Controls.Add($statusPanel, 1, 0)
$hero.SetRowSpan($statusPanel, 3)

$lblEnvStatus = New-CHRLabel "Environment: checking..."
$lblProjectStatus = New-CHRLabel "Project: not selected"
$lblRowsStatus = New-CHRLabel "Records: not loaded"
$lblSelectedStatus = New-CHRLabel "Selected: 0"
$statusPanel.Controls.Add($lblEnvStatus, 0, 0)
$statusPanel.Controls.Add($lblProjectStatus, 0, 1)
$statusPanel.Controls.Add($lblRowsStatus, 0, 2)
$statusPanel.Controls.Add($lblSelectedStatus, 0, 3)

$restorePanel = New-Object System.Windows.Forms.TableLayoutPanel
$restorePanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$restorePanel.Padding = New-Object System.Windows.Forms.Padding(18, 12, 18, 12)
$restorePanel.ColumnCount = 4
$restorePanel.RowCount = 3
$restorePanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 132))) | Out-Null
$restorePanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
$restorePanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 142))) | Out-Null
$restorePanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 142))) | Out-Null
$restorePanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 34))) | Out-Null
$restorePanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 42))) | Out-Null
$restorePanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
$main.Controls.Add($restorePanel, 0, 1)

$restorePanel.Controls.Add((New-CHRLabel "Restore into"), 0, 0)
$txtProjectRoot = New-Object System.Windows.Forms.TextBox
$txtProjectRoot.Dock = [System.Windows.Forms.DockStyle]::Fill
$restorePanel.Controls.Add($txtProjectRoot, 1, 0)
$btnChooseProjectAction = New-CHRButton "Choose project" 132 28
$btnBrowseProject = New-CHRButton "Browse folder" 132 28
$restorePanel.Controls.Add($btnChooseProjectAction, 2, 0)
$restorePanel.Controls.Add($btnBrowseProject, 3, 0)

$lblSimpleHelp = New-Object System.Windows.Forms.Label
$lblSimpleHelp.Text = "Most users only need these four buttons. Use More tools only for importing from another .codex folder or rolling back a backup."
$lblSimpleHelp.Dock = [System.Windows.Forms.DockStyle]::Fill
$lblSimpleHelp.ForeColor = [System.Drawing.Color]::FromArgb(82, 88, 96)
$restorePanel.Controls.Add($lblSimpleHelp, 0, 1)
$restorePanel.SetColumnSpan($lblSimpleHelp, 4)

$primaryActions = New-Object System.Windows.Forms.FlowLayoutPanel
$primaryActions.Dock = [System.Windows.Forms.DockStyle]::Fill
$primaryActions.WrapContents = $false
$restorePanel.Controls.Add($primaryActions, 0, 2)
$restorePanel.SetColumnSpan($primaryActions, 4)

$btnLoad = New-CHRButton "Load records" 132 34
$btnSelectOld = New-CHRButton "Select hidden" 132 34
$btnDryRun = New-CHRButton "Preview" 132 34 ([System.Drawing.Color]::FromArgb(224, 237, 252))
$btnRestore = New-CHRButton "Restore selected" 150 34 ([System.Drawing.Color]::FromArgb(218, 242, 225))
$btnMoreTools = New-CHRButton "More tools..." 120 34
foreach ($button in @($btnLoad, $btnSelectOld, $btnDryRun, $btnRestore, $btnMoreTools)) { $primaryActions.Controls.Add($button) }

$advancedPanel = New-Object System.Windows.Forms.TableLayoutPanel
$advancedPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$advancedPanel.Padding = New-Object System.Windows.Forms.Padding(18, 8, 18, 8)
$advancedPanel.ColumnCount = 4
$advancedPanel.RowCount = 4
$advancedPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 132))) | Out-Null
$advancedPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
$advancedPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 132))) | Out-Null
$advancedPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 132))) | Out-Null
for ($i = 0; $i -lt 4; $i++) { $advancedPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 32))) | Out-Null }
$advancedPanel.Visible = $false
$main.Controls.Add($advancedPanel, 0, 2)

$txtCodexHome = New-Object System.Windows.Forms.TextBox
$txtCodexHome.Text = Get-CHRDefaultCodexHome
$txtCodexHome.Dock = [System.Windows.Forms.DockStyle]::Fill
$btnDetect = New-CHRButton "Re-check" 122 26
$advancedPanel.Controls.Add((New-CHRLabel "Codex home"), 0, 0)
$advancedPanel.Controls.Add($txtCodexHome, 1, 0)
$advancedPanel.Controls.Add($btnDetect, 2, 0)

$txtSourceSessions = New-Object System.Windows.Forms.TextBox
$txtSourceSessions.Dock = [System.Windows.Forms.DockStyle]::Fill
$btnBrowseSource = New-CHRButton "Browse" 122 26
$btnFindSources = New-CHRButton "Find sources" 122 26
$advancedPanel.Controls.Add((New-CHRLabel "Import source"), 0, 1)
$advancedPanel.Controls.Add($txtSourceSessions, 1, 1)
$advancedPanel.Controls.Add($btnBrowseSource, 2, 1)
$advancedPanel.Controls.Add($btnFindSources, 3, 1)

$txtBackupRoot = New-Object System.Windows.Forms.TextBox
$txtBackupRoot.Text = Get-CHRDefaultBackupRoot
$txtBackupRoot.Dock = [System.Windows.Forms.DockStyle]::Fill
$btnBrowseBackup = New-CHRButton "Browse" 122 26
$btnBackups = New-CHRButton "Rollback" 122 26
$advancedPanel.Controls.Add((New-CHRLabel "Backup folder"), 0, 2)
$advancedPanel.Controls.Add($txtBackupRoot, 1, 2)
$advancedPanel.Controls.Add($btnBrowseBackup, 2, 2)
$advancedPanel.Controls.Add($btnBackups, 3, 2)

$txtTemplateThreadId = New-Object System.Windows.Forms.TextBox
$txtTemplateThreadId.Dock = [System.Windows.Forms.DockStyle]::Fill
$chkOnlyOld = New-Object System.Windows.Forms.CheckBox
$chkOnlyOld.Text = "Hidden only"
$chkOnlyOld.Dock = [System.Windows.Forms.DockStyle]::Fill
$chkNoTouch = New-Object System.Windows.Forms.CheckBox
$chkNoTouch.Text = "Do not bump"
$chkNoTouch.Dock = [System.Windows.Forms.DockStyle]::Fill
$advancedPanel.Controls.Add((New-CHRLabel "Template thread"), 0, 3)
$advancedPanel.Controls.Add($txtTemplateThreadId, 1, 3)
$advancedPanel.Controls.Add($chkOnlyOld, 2, 3)
$advancedPanel.Controls.Add($chkNoTouch, 3, 3)

$btnImport = New-CHRButton "Import sessions" 122 26
$btnDetectAction = New-Object System.Windows.Forms.Button
$btnChooseProject = New-Object System.Windows.Forms.Button
$btnFindSourcesAction = New-Object System.Windows.Forms.Button
$btnClearSelection = New-CHRButton "Clear selected" 116 28

$filterBar = New-Object System.Windows.Forms.TableLayoutPanel
$filterBar.Dock = [System.Windows.Forms.DockStyle]::Fill
$filterBar.Padding = New-Object System.Windows.Forms.Padding(18, 6, 18, 4)
$filterBar.ColumnCount = 4
$filterBar.RowCount = 1
$filterBar.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 60))) | Out-Null
$filterBar.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 260))) | Out-Null
$filterBar.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 110))) | Out-Null
$filterBar.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
$main.Controls.Add($filterBar, 0, 3)

$filterBar.Controls.Add((New-CHRLabel "Search"), 0, 0)
$txtSearch = New-Object System.Windows.Forms.TextBox
$txtSearch.Dock = [System.Windows.Forms.DockStyle]::Fill
$filterBar.Controls.Add($txtSearch, 1, 0)
$cmbStatusFilter = New-Object System.Windows.Forms.ComboBox
$cmbStatusFilter.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$cmbStatusFilter.Dock = [System.Windows.Forms.DockStyle]::Fill
[void]$cmbStatusFilter.Items.Add("All")
[void]$cmbStatusFilter.Items.Add("Hidden")
[void]$cmbStatusFilter.Items.Add("Visible")
$cmbStatusFilter.SelectedItem = "All"
$filterBar.Controls.Add($cmbStatusFilter, 2, 0)
$btnShowLog = New-CHRButton "Show log" 116 28

$toolTip = New-Object System.Windows.Forms.ToolTip
$toolTip.AutoPopDelay = 12000
$toolTip.InitialDelay = 400
$toolTip.ReshowDelay = 100
$toolTip.SetToolTip($txtProjectRoot, "The project that the recovered chats should appear under in Codex Desktop.")
$toolTip.SetToolTip($btnLoad, "List chats for the selected project.")
$toolTip.SetToolTip($btnSelectOld, "Select rows that look hidden or outdated.")
$toolTip.SetToolTip($btnDryRun, "Preview the restore without changing files.")
$toolTip.SetToolTip($btnRestore, "Create a backup, then repair the selected chats.")
$toolTip.SetToolTip($btnMoreTools, "Show import, rollback, backup, and advanced settings.")
$toolTip.SetToolTip($txtCodexHome, "Usually %USERPROFILE%\.codex. This is where Codex Desktop stores local history.")
$toolTip.SetToolTip($txtSourceSessions, "Optional. Use this only when importing rollout-*.jsonl files from another .codex\sessions folder.")
$toolTip.SetToolTip($txtBackupRoot, "Backups are created here before Restore or Import writes anything.")
$toolTip.SetToolTip($txtTemplateThreadId, "Advanced. Leave blank unless you want to copy Desktop metadata from a specific visible thread.")
$toolTip.SetToolTip($chkOnlyOld, "When loading records, show only chats that look hidden/outdated.")
$toolTip.SetToolTip($chkNoTouch, "Advanced. Prevents updated_at_ms from being refreshed, so restored chats may not move to the top.")

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
$main.Controls.Add($grid, 0, 4)

$colSelected = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn
$colSelected.Name = "Selected"
$colSelected.HeaderText = ""
$colSelected.Width = 36
$colSelected.FillWeight = 8
$grid.Columns.Add($colSelected) | Out-Null
foreach ($col in @(
    @{Name="Number"; Header="#"; Weight=10},
    @{Name="Status"; Header="Status"; Weight=14},
    @{Name="Title"; Header="Title"; Weight=80},
    @{Name="ThreadId"; Header="Thread Id"; Weight=48},
    @{Name="UpdatedAt"; Header="Updated"; Weight=34},
    @{Name="Project"; Header="Project"; Weight=58}
)) {
    $c = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $c.Name = $col.Name
    $c.HeaderText = $col.Header
    $c.ReadOnly = $true
    $c.FillWeight = $col.Weight
    $grid.Columns.Add($c) | Out-Null
}

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Dock = [System.Windows.Forms.DockStyle]::Fill
$txtLog.Multiline = $true
$txtLog.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$txtLog.ReadOnly = $true
$txtLog.Font = New-Object System.Drawing.Font("Consolas", 9)
$txtLog.Visible = $false
$main.Controls.Add($txtLog, 0, 5)

$moreMenu = New-Object System.Windows.Forms.ContextMenuStrip
$menuAdvanced = $moreMenu.Items.Add("Show advanced settings")
$menuClear = $moreMenu.Items.Add("Clear selection")
$menuLog = $moreMenu.Items.Add("Show log")
$menuImport = $moreMenu.Items.Add("Import sessions from another Codex folder")
$menuFind = $moreMenu.Items.Add("Find source folders")
$menuRollback = $moreMenu.Items.Add("Backups / rollback")
$menuDetect = $moreMenu.Items.Add("Re-check environment")
$btnMoreTools.Add_Click({ $moreMenu.Show($btnMoreTools, 0, $btnMoreTools.Height) })
$menuAdvanced.Add_Click({
    $advancedPanel.Visible = -not $advancedPanel.Visible
    $main.RowStyles[2].Height = if ($advancedPanel.Visible) { 144 } else { 0 }
    $menuAdvanced.Text = if ($advancedPanel.Visible) { "Hide advanced settings" } else { "Show advanced settings" }
})
$menuClear.Add_Click({ Clear-SelectedRows })
$menuLog.Add_Click({
    $txtLog.Visible = -not $txtLog.Visible
    $main.RowStyles[5].Height = if ($txtLog.Visible) { 118 } else { 0 }
    $menuLog.Text = if ($txtLog.Visible) { "Hide log" } else { "Show log" }
})
$menuImport.Add_Click({ Invoke-Safe { Invoke-ImportSessions } })
$menuFind.Add_Click({ Invoke-Safe { Invoke-FindSources } })
$menuRollback.Add_Click({ Invoke-Safe { Invoke-Backups } })
$menuDetect.Add_Click({ Invoke-Safe { Invoke-Detect } })

$btnDetect.Add_Click({ Invoke-Safe { Invoke-Detect } })
$btnDetectAction.Add_Click({ Invoke-Safe { Invoke-Detect } })
$btnBrowseProject.Add_Click({ $path = Select-Folder "Choose project root" $txtProjectRoot.Text; if ($path) { $txtProjectRoot.Text = $path; Update-Guidance } })
$btnChooseProject.Add_Click({ Invoke-Safe { Invoke-ChooseProject } })
$btnChooseProjectAction.Add_Click({ Invoke-Safe { Invoke-ChooseProject } })
$btnBrowseSource.Add_Click({ $path = Select-Folder "Choose external .codex sessions folder" $txtSourceSessions.Text; if ($path) { $txtSourceSessions.Text = $path; Update-Guidance "Source selected. Click Import Sessions to scan it, or continue normal restore with 3 Load Records." } })
$btnFindSources.Add_Click({ Invoke-Safe { Invoke-FindSources } })
$btnFindSourcesAction.Add_Click({ Invoke-Safe { Invoke-FindSources } })
$btnBrowseBackup.Add_Click({ $path = Select-Folder "Choose backup folder" $txtBackupRoot.Text; if ($path) { $txtBackupRoot.Text = $path; Update-Guidance } })
$btnLoad.Add_Click({ Invoke-Safe { Load-Threads } })
$btnSelectOld.Add_Click({ Select-OldRows })
$btnClearSelection.Add_Click({ Clear-SelectedRows })
$btnDryRun.Add_Click({ Invoke-Safe { Invoke-DryRun } })
$btnRestore.Add_Click({ Invoke-Safe { Invoke-RestoreSelected } })
$btnImport.Add_Click({ Invoke-Safe { Invoke-ImportSessions } })
$btnBackups.Add_Click({ Invoke-Safe { Invoke-Backups } })
$txtSearch.Add_TextChanged({ Apply-GridFilter })
$cmbStatusFilter.Add_SelectedIndexChanged({ Apply-GridFilter })
$grid.Add_CurrentCellDirtyStateChanged({ if ($grid.IsCurrentCellDirty) { $grid.CommitEdit([System.Windows.Forms.DataGridViewDataErrorContexts]::Commit) | Out-Null } })
$grid.Add_CellValueChanged({ Update-Guidance })
$grid.Add_CellDoubleClick({ Show-ThreadDetails })

$form.Add_Shown({ Update-Guidance; Invoke-Safe { Invoke-Detect } })

[void][System.Windows.Forms.Application]::Run($form)
