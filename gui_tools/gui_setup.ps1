Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$xamlPath = Join-Path $PSScriptRoot "gui_setup.xaml"
if (-not (Test-Path $xamlPath)) {
    [System.Windows.MessageBox]::Show("XAML file not found: $xamlPath", "Error", "OK", "Error")
    return
}

[xml]$xaml = Get-Content -Raw -Path $xamlPath
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$templateBox = $window.FindName("TemplatePathTextBox")
$outputBox = $window.FindName("OutputPathTextBox")

$enableChocoInstall = $window.FindName("EnableChocoInstallCheckBox")
$enableWingetInstall = $window.FindName("EnableWingetInstallCheckBox")
$enableScoopInstall = $window.FindName("EnableScoopInstallCheckBox")
$enableVCRedist = $window.FindName("EnableVCRedistCheckBox")
$enableDxSetup = $window.FindName("EnableDxSetupCheckBox")
$enableCleanup = $window.FindName("EnableCleanupCheckBox")
$enableLog = $window.FindName("EnableLogCheckBox")

$vcUrlBox = $window.FindName("VcUrlTextBox")
$vcArgsBox = $window.FindName("VcArgsTextBox")
$dxUrlBox = $window.FindName("DxUrlTextBox")

$urlGrid = $window.FindName("UrlGrid")

$wingetGrid = $window.FindName("WingetGrid")
$chocoGrid = $window.FindName("ChocoGrid")
$scoopGrid = $window.FindName("ScoopGrid")
$fileOpsGrid = $window.FindName("FileOpsGrid")
$networkGrid = $window.FindName("NetworkGrid")
$commandsGrid = $window.FindName("CommandsGrid")
$templateBtn = $window.FindName("TemplateBrowseButton")
$outputBtn = $window.FindName("OutputBrowseButton")
$addRowBtn = $window.FindName("AddRowButton")
$removeRowBtn = $window.FindName("RemoveRowButton")
$fileOpsAddBtn = $window.FindName("FileOpsAddButton")
$fileOpsRemoveBtn = $window.FindName("FileOpsRemoveButton")
$networkAddBtn = $window.FindName("NetworkAddButton")
$networkRemoveBtn = $window.FindName("NetworkRemoveButton")
$commandsAddBtn = $window.FindName("CommandsAddButton")
$commandsRemoveBtn = $window.FindName("CommandsRemoveButton")
$generateBtn = $window.FindName("GenerateButton")

$projectRoot = Split-Path -Parent $PSScriptRoot
$templateBox.Text = (Join-Path $projectRoot "setup_template.ps1")
$outputBox.Text = (Join-Path $projectRoot "setup.ps1")

$vcUrlBox.Text = "https://github.com/abbodi1406/vcredist/releases/latest/download/VisualCppRedist_AIO_x86_x64.exe"
$vcArgsBox.Text = "/ai;/gm2"
$dxUrlBox.Text = "https://download.microsoft.com/download/1/7/1/1718ccc4-6315-4d8e-9543-8e28a4e18c4c/dxwebsetup.exe"


$enableChocoInstall.IsChecked = $true
$enableWingetInstall.IsChecked = $true
$enableScoopInstall.IsChecked = $true
$enableVCRedist.IsChecked = $true
$enableDxSetup.IsChecked = $true
$enableCleanup.IsChecked = $true
$enableLog.IsChecked = $true

function New-PackageRow {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [bool]$Enabled = $true,
        [string]$PackageName = "",
        [string]$Version = ""
    )
    if ($PSCmdlet.ShouldProcess($PackageName, "Create package row")) {
        [PSCustomObject]@{
            Enabled = $Enabled
            PackageName = $PackageName
            Version = $Version
        }
    }
}

function Expand-PlaceholderText {
    param(
        [string]$Content,
        [hashtable]$Map
    )
    foreach ($key in $Map.Keys) {
        $value = $Map[$key]
        $pattern = "\$\{" + [Regex]::Escape($key) + "\}"
        $Content = [Regex]::Replace($Content, $pattern, [string]$value)
    }
    return $Content
}

function ConvertTo-BoolString([object]$Value) {
    $boolValue = $false
    if ($null -ne $Value) {
        try {
            $boolValue = [System.Convert]::ToBoolean($Value)
        } catch {
            $boolValue = $false
        }
    }
    if ($boolValue) { return '$true' }
    return '$false'
}

function ConvertTo-PowerShellString {
    param([string]$Value)
    return $Value.Replace('"', '`"')
}

function New-UrlRow {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [bool]$Enabled = $true,
        [string]$Name = "",
        [string]$Url = "",
        [bool]$SaveToTemp = $true,
        [string]$Filename = "",
        [string]$InstallArgs = "",
        [bool]$RemoveInstaller = $false
    )
    if ($PSCmdlet.ShouldProcess($Name, "Create URL install row")) {
        [PSCustomObject]@{
            Enabled = $Enabled
            Name = $Name
            Url = $Url
            SaveToTemp = $SaveToTemp
            Filename = $Filename
            InstallArgs = $InstallArgs
            RemoveInstaller = $RemoveInstaller
        }
    }
}

function Get-UrlInstallCommand {
    param([System.Collections.IEnumerable]$Items)
    $lines = New-Object System.Collections.Generic.List[string]

    foreach ($item in $Items) {
        if (-not $item.Enabled) { continue }
        if ([string]::IsNullOrWhiteSpace($item.Url)) { continue }
        if ([string]::IsNullOrWhiteSpace($item.Filename)) { continue }

        $url = ConvertTo-PowerShellString $item.Url
        
        # Build output path
        if ($item.SaveToTemp) {
            $out = "`$env:TEMP\$(ConvertTo-PowerShellString $item.Filename)"
        } else {
            $out = ConvertTo-PowerShellString $item.Filename
        }
        
        $hasArgs = -not [string]::IsNullOrWhiteSpace($item.InstallArgs)
        $hasRemove = $item.RemoveInstaller
        
        if ($hasArgs -and $hasRemove) {
            $argList = $item.InstallArgs -split ";" | ForEach-Object { $_.Trim() } | Where-Object { $_ }
            $argItems = $argList | ForEach-Object { "`"$((ConvertTo-PowerShellString $_))`"" }
            $lines.Add("Install-SoftwareFromUrl -Url `"$url`" -OutputPath `"$out`" -InstallArguments @($($argItems -join ", ")) -RemoveInstaller")
        } elseif ($hasArgs) {
            $argList = $item.InstallArgs -split ";" | ForEach-Object { $_.Trim() } | Where-Object { $_ }
            $argItems = $argList | ForEach-Object { "`"$((ConvertTo-PowerShellString $_))`"" }
            $lines.Add("Install-SoftwareFromUrl -Url `"$url`" -OutputPath `"$out`" -InstallArguments @($($argItems -join ", "))")
        } elseif ($hasRemove) {
            $lines.Add("Install-SoftwareFromUrl -Url `"$url`" -OutputPath `"$out`" -RemoveInstaller")
        } else {
            $lines.Add("Install-SoftwareFromUrl -Url `"$url`" -OutputPath `"$out`"")
        }
    }

    if ($lines.Count -eq 0) {
        return "# (no URL installs selected)"
    }

    return ($lines -join "`r`n")
}

$packageListPath = Join-Path $projectRoot "package_list.json"
$urlListPath = Join-Path $projectRoot "url_list.json"
$wingetItems = New-Object System.Collections.ObjectModel.ObservableCollection[object]
$chocoItems = New-Object System.Collections.ObjectModel.ObservableCollection[object]
$scoopItems = New-Object System.Collections.ObjectModel.ObservableCollection[object]
$urlItems = New-Object System.Collections.ObjectModel.ObservableCollection[object]
$fileOpsItems = New-Object System.Collections.ObjectModel.ObservableCollection[object]
$networkItems = New-Object System.Collections.ObjectModel.ObservableCollection[object]
$commandsItems = New-Object System.Collections.ObjectModel.ObservableCollection[object]

# Set DataContext for ComboBox options
$fileOperations = @("Copy", "Move", "Delete-Recycle", "Delete-Permanent", "Extract-ZIP")
$networkTools = @("Firewall-Add", "Firewall-Remove", "Hosts-Add", "Hosts-Remove", "Hosts-AddPreset", "Hosts-RemovePreset")
$window.DataContext = @{
    FileOperations = $fileOperations
    NetworkTools = $networkTools
}

if (Test-Path $packageListPath) {
    try {
        $json = Get-Content -Raw -Path $packageListPath | ConvertFrom-Json
        foreach ($item in $json) {
            $row = New-PackageRow -Enabled ($item.Enabled -ne $false) -PackageName $item.PackageName -Version $item.Version
            switch ($item.Provider) {
                "Chocolatey" { $chocoItems.Add($row) }
                "Scoop" { $scoopItems.Add($row) }
                default { $wingetItems.Add($row) }
            }
        }
    } catch {
        $wingetItems.Add((New-PackageRow -PackageName "Google.Chrome"))
        $wingetItems.Add((New-PackageRow -PackageName "Mozilla.Firefox"))
    }
} else {
    $wingetItems.Add((New-PackageRow -PackageName "Google.Chrome"))
    $wingetItems.Add((New-PackageRow -PackageName "Mozilla.Firefox"))
}

$wingetGrid.ItemsSource = $wingetItems
$chocoGrid.ItemsSource = $chocoItems
$scoopGrid.ItemsSource = $scoopItems
$urlGrid.ItemsSource = $urlItems
$fileOpsGrid.ItemsSource = $fileOpsItems
$networkGrid.ItemsSource = $networkItems
$commandsGrid.ItemsSource = $commandsItems

if (Test-Path $urlListPath) {
    try {
        $json = Get-Content -Raw -Path $urlListPath | ConvertFrom-Json
        foreach ($item in $json) {
            $urlItems.Add((
                New-UrlRow `
                    -Enabled ($item.Enabled -ne $false) `
                    -Name $item.Name `
                    -Url $item.Url `
                    -SaveToTemp (if ($null -ne $item.SaveToTemp) { [bool]$item.SaveToTemp } else { $true }) `
                    -Filename $item.Filename `
                    -InstallArgs $item.InstallArgs `
                    -RemoveInstaller ([bool]$item.RemoveInstaller)
            ))
        }
    } catch {
        $urlItems.Add((New-UrlRow -Name "PostgreSQL" -Url "https://get.enterprisedb.com/postgresql/postgresql-17.3-1-windows-x64.exe" -SaveToTemp $true -Filename "postgresql-17.3-1-windows-x64.exe"))
        $urlItems.Add((New-UrlRow -Name "IDM" -Url "https://download.internetdownloadmanager.com/idman641build2.exe" -SaveToTemp $true -Filename "idm_installer.exe" -InstallArgs "/silent" -RemoveInstaller $true))
    }
} else {
    $urlItems.Add((New-UrlRow -Name "PostgreSQL" -Url "https://get.enterprisedb.com/postgresql/postgresql-17.3-1-windows-x64.exe" -SaveToTemp $true -Filename "postgresql-17.3-1-windows-x64.exe"))
    $urlItems.Add((New-UrlRow -Name "IDM" -Url "https://download.internetdownloadmanager.com/idman641build2.exe" -SaveToTemp $true -Filename "idm_installer.exe" -InstallArgs "/silent" -RemoveInstaller $true))
}


function Get-PackageCommand {
    param(
        [System.Collections.IEnumerable]$WingetItems,
        [System.Collections.IEnumerable]$ChocoItems,
        [System.Collections.IEnumerable]$ScoopItems
    )
    $lines = New-Object System.Collections.Generic.List[string]

    foreach ($item in $WingetItems) {
        if (-not $item.Enabled) { continue }
        if ([string]::IsNullOrWhiteSpace($item.PackageName)) { continue }
        $name = ConvertTo-PowerShellString $item.PackageName
        if ([string]::IsNullOrWhiteSpace($item.Version)) {
            $lines.Add("Install-WithWinget -PackageName `"$name`"")
        } else {
            $ver = ConvertTo-PowerShellString $item.Version
            $lines.Add("Install-WithWinget -PackageName `"$name`" -Version `"$ver`"")
        }
    }

    foreach ($item in $ChocoItems) {
        if (-not $item.Enabled) { continue }
        if ([string]::IsNullOrWhiteSpace($item.PackageName)) { continue }
        $name = ConvertTo-PowerShellString $item.PackageName
        if ([string]::IsNullOrWhiteSpace($item.Version)) {
            $lines.Add("Install-WithChocolatey -PackageName `"$name`"")
        } else {
            $ver = ConvertTo-PowerShellString $item.Version
            $lines.Add("Install-WithChocolatey -PackageName `"$name`" -Version `"$ver`"")
        }
    }

    foreach ($item in $ScoopItems) {
        if (-not $item.Enabled) { continue }
        if ([string]::IsNullOrWhiteSpace($item.PackageName)) { continue }
        $name = ConvertTo-PowerShellString $item.PackageName
        $lines.Add("Install-WithScoop -PackageName `"$name`"")
    }

    if ($lines.Count -eq 0) {
        $lines.Add("# (no packages selected)")
    }

    return ($lines -join "`r`n")
}

function New-FileOpRow {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [bool]$Enabled = $true,
        [string]$Operation = "Copy",
        [string]$SourcePath = "",
        [string]$DestPath = "",
        [bool]$Recurse = $false,
        [bool]$Force = $false
    )
    if ($PSCmdlet.ShouldProcess($Operation, "Create file operation row")) {
        [PSCustomObject]@{
            Enabled = $Enabled
            Operation = $Operation
            SourcePath = $SourcePath
            DestPath = $DestPath
            Recurse = $Recurse
            Force = $Force
        }
    }
}

function New-NetworkRow {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [bool]$Enabled = $true,
        [string]$Tool = "Firewall-Add",
        [string]$Path = "",
        [string]$Action = "",
        [string]$Extra = ""
    )
    if ($PSCmdlet.ShouldProcess($Tool, "Create network tool row")) {
        [PSCustomObject]@{
            Enabled = $Enabled
            Tool = $Tool
            Path = $Path
            Action = $Action
            Extra = $Extra
        }
    }
}

function New-CommandRow {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [bool]$Enabled = $true,
        [string]$Command = "",
        [bool]$WaitForExit = $true,
        [string]$Shell = "powershell"
    )
    if ($PSCmdlet.ShouldProcess($Command, "Create command row")) {
        [PSCustomObject]@{
            Enabled = $Enabled
            Command = $Command
            WaitForExit = $WaitForExit
            Shell = $Shell
        }
    }
}

function Get-FileOpsCommand {
    param([System.Collections.IEnumerable]$Items)
    $lines = New-Object System.Collections.Generic.List[string]

    foreach ($item in $Items) {
        if (-not $item.Enabled) { continue }
        if ([string]::IsNullOrWhiteSpace($item.SourcePath)) { continue }

        $src = ConvertTo-PowerShellString $item.SourcePath
        
        switch ($item.Operation) {
            "Copy" {
                if ([string]::IsNullOrWhiteSpace($item.DestPath)) { continue }
                $dest = ConvertTo-PowerShellString $item.DestPath
                if ($item.Recurse -and $item.Force) {
                    $lines.Add("Copy-FileHandler -SourcePath `"$src`" -DestinationPath `"$dest`" -Recurse -Force")
                } elseif ($item.Recurse) {
                    $lines.Add("Copy-FileHandler -SourcePath `"$src`" -DestinationPath `"$dest`" -Recurse")
                } elseif ($item.Force) {
                    $lines.Add("Copy-FileHandler -SourcePath `"$src`" -DestinationPath `"$dest`" -Force")
                } else {
                    $lines.Add("Copy-FileHandler -SourcePath `"$src`" -DestinationPath `"$dest`"")
                }
            }
            "Move" {
                if ([string]::IsNullOrWhiteSpace($item.DestPath)) { continue }
                $dest = ConvertTo-PowerShellString $item.DestPath
                if ($item.Force) {
                    $lines.Add("Move-FileHandler -SourcePath `"$src`" -DestinationPath `"$dest`" -Force")
                } else {
                    $lines.Add("Move-FileHandler -SourcePath `"$src`" -DestinationPath `"$dest`"")
                }
            }
            "Delete-Recycle" {
                $lines.Add("Remove-FileToRecycleBin -Path `"$src`"")
            }
            "Delete-Permanent" {
                $lines.Add("Remove-FileVerbose -Path `"$src`"")
            }
            "Extract-ZIP" {
                if ([string]::IsNullOrWhiteSpace($item.DestPath)) { continue }
                $dest = ConvertTo-PowerShellString $item.DestPath
                if ($item.Force) {
                    $lines.Add("Expand-ZipFile -ZipFilePath `"$src`" -DestinationPath `"$dest`" -Force")
                } else {
                    $lines.Add("Expand-ZipFile -ZipFilePath `"$src`" -DestinationPath `"$dest`"")
                }
            }
        }
    }

    if ($lines.Count -eq 0) {
        return "# (no file operations selected)"
    }

    return ($lines -join "`r`n")
}

function Get-NetworkCommand {
    param([System.Collections.IEnumerable]$Items)
    $lines = New-Object System.Collections.Generic.List[string]

    foreach ($item in $Items) {
        if (-not $item.Enabled) { continue }
        if ([string]::IsNullOrWhiteSpace($item.Path)) { continue }

        $path = ConvertTo-PowerShellString $item.Path
        $action = ConvertTo-PowerShellString $item.Action
        $extra = ConvertTo-PowerShellString $item.Extra
        
        switch ($item.Tool) {
            "Firewall-Add" {
                if ([string]::IsNullOrWhiteSpace($action)) { $action = "Block" }
                if ([string]::IsNullOrWhiteSpace($extra)) { $extra = "All" }
                $lines.Add("Set-FirewallRule -Path `"$path`" -Action `"$action`" -Direction `"$extra`"")
            }
            "Firewall-Remove" {
                if ([string]::IsNullOrWhiteSpace($action)) { $action = "Block" }
                if ([string]::IsNullOrWhiteSpace($extra)) { $extra = "All" }
                $lines.Add("Remove-FirewallRule -Path `"$path`" -Action `"$action`" -Direction `"$extra`"")
            }
            "Hosts-Add" {
                if ([string]::IsNullOrWhiteSpace($action)) { continue }
                $lines.Add("Set-HostEntry -Action Add -IPAddress `"$action`" -Hostname `"$path`"")
            }
            "Hosts-Remove" {
                $lines.Add("Set-HostEntry -Action Remove -Hostname `"$path`"")
            }
            "Hosts-AddPreset" {
                $lines.Add("Set-HostEntry -Action Add -PresetUrl `"$path`"")
            }
            "Hosts-RemovePreset" {
                $lines.Add("Set-HostEntry -Action Remove -PresetUrl `"$path`"")
            }
        }
    }

    if ($lines.Count -eq 0) {
        return "# (no network operations selected)"
    }

    return ($lines -join "`r`n")
}

function Get-CommandsCommand {
    param([System.Collections.IEnumerable]$Items)
    $lines = New-Object System.Collections.Generic.List[string]

    foreach ($item in $Items) {
        if (-not $item.Enabled) { continue }
        if ([string]::IsNullOrWhiteSpace($item.Command)) { continue }

        $cmd = ConvertTo-PowerShellString $item.Command
        $shell = if ([string]::IsNullOrWhiteSpace($item.Shell)) { "powershell" } else { $item.Shell.ToLower() }
        
        if ($item.WaitForExit) {
            $lines.Add("Invoke-Command -Commands @(`"$cmd`") -Shell '$shell' -WaitForExit")
        } else {
            $lines.Add("Invoke-Command -Commands @(`"$cmd`") -Shell '$shell'")
        }
    }

    if ($lines.Count -eq 0) {
        return "# (no commands selected)"
    }

    return ($lines -join "`r`n")
}

$templateBtn.Add_Click({
    $dialog = New-Object Microsoft.Win32.OpenFileDialog
    $dialog.Filter = "PowerShell Template (*.ps1)|*.ps1|All Files (*.*)|*.*"
    if ($dialog.ShowDialog()) { $templateBox.Text = $dialog.FileName }
})

$outputBtn.Add_Click({
    $dialog = New-Object Microsoft.Win32.SaveFileDialog
    $dialog.Filter = "PowerShell Script (*.ps1)|*.ps1|All Files (*.*)|*.*"
    $dialog.FileName = [System.IO.Path]::GetFileName($outputBox.Text)
    if ($dialog.ShowDialog()) { $outputBox.Text = $dialog.FileName }
})

function Get-ActiveGridInfo {
    if ($wingetGrid.IsVisible) { return @{ Grid = $wingetGrid; Items = $wingetItems; RowFactory = { New-PackageRow -Enabled $true -PackageName "" -Version "" } } }
    if ($chocoGrid.IsVisible) { return @{ Grid = $chocoGrid; Items = $chocoItems; RowFactory = { New-PackageRow -Enabled $true -PackageName "" -Version "" } } }
    if ($scoopGrid.IsVisible) { return @{ Grid = $scoopGrid; Items = $scoopItems; RowFactory = { New-PackageRow -Enabled $true -PackageName "" -Version "" } } }
    if ($urlGrid.IsVisible) { return @{ Grid = $urlGrid; Items = $urlItems; RowFactory = { New-UrlRow -Enabled $true -Name "" -Url "" -SaveToTemp $true -Filename "" -InstallArgs "" -RemoveInstaller $false } } }
    if ($fileOpsGrid.IsVisible) { return @{ Grid = $fileOpsGrid; Items = $fileOpsItems; RowFactory = { New-FileOpRow -Enabled $true -Operation "Copy" -SourcePath "" -DestPath "" -Recurse $false -Force $false } } }
    if ($networkGrid.IsVisible) { return @{ Grid = $networkGrid; Items = $networkItems; RowFactory = { New-NetworkRow -Enabled $true -Tool "Firewall-Add" -Path "" -Action "" -Extra "" } } }
    if ($commandsGrid.IsVisible) { return @{ Grid = $commandsGrid; Items = $commandsItems; RowFactory = { New-CommandRow -Enabled $true -Command "" -WaitForExit $true -Shell "powershell" } } }
    return $null
}

$addRowBtn.Add_Click({
    $active = Get-ActiveGridInfo
    if (-not $active) { return }
    $active.Items.Add((& $active.RowFactory))
})

$removeRowBtn.Add_Click({
    $active = Get-ActiveGridInfo
    if (-not $active) { return }
    $selected = @($active.Grid.SelectedItems)
    foreach ($item in $selected) {
        $active.Items.Remove($item) | Out-Null
    }
})

$fileOpsAddBtn.Add_Click({
    $fileOpsItems.Add((New-FileOpRow -Enabled $true -Operation "Copy" -SourcePath "" -DestPath "" -Recurse $false -Force $false))
})

$fileOpsRemoveBtn.Add_Click({
    $selected = @($fileOpsGrid.SelectedItems)
    foreach ($item in $selected) {
        $fileOpsItems.Remove($item) | Out-Null
    }
})

$networkAddBtn.Add_Click({
    $networkItems.Add((New-NetworkRow -Enabled $true -Tool "Firewall-Add" -Path "" -Action "" -Extra ""))
})

$networkRemoveBtn.Add_Click({
    $selected = @($networkGrid.SelectedItems)
    foreach ($item in $selected) {
        $networkItems.Remove($item) | Out-Null
    }
})

$commandsAddBtn.Add_Click({
    $commandsItems.Add((New-CommandRow -Enabled $true -Command "" -WaitForExit $true -Shell "powershell"))
})

$commandsRemoveBtn.Add_Click({
    $selected = @($commandsGrid.SelectedItems)
    foreach ($item in $selected) {
        $commandsItems.Remove($item) | Out-Null
    }
})

$generateBtn.Add_Click({
    if (-not (Test-Path $templateBox.Text)) {
        [System.Windows.MessageBox]::Show("Template file not found.", "Error", "OK", "Error")
        return
    }

    if ([string]::IsNullOrWhiteSpace($outputBox.Text)) {
        [System.Windows.MessageBox]::Show("Please choose an output file.", "Error", "OK", "Error")
        return
    }

    $content = Get-Content -Raw -Path $templateBox.Text
    $packageBlock = Get-PackageCommand -WingetItems $wingetItems -ChocoItems $chocoItems -ScoopItems $scoopItems
    $urlBlock = Get-UrlInstallCommand -Items $urlItems
    $fileOpsBlock = Get-FileOpsCommand -Items $fileOpsItems
    $networkBlock = Get-NetworkCommand -Items $networkItems
    $commandsBlock = Get-CommandsCommand -Items $commandsItems

    if ($content -notmatch "# <PACKAGE_LIST_MARKER>") {
        [System.Windows.MessageBox]::Show("Package list marker not found in template.", "Error", "OK", "Error")
        return
    }

    $content = $content -replace [Regex]::Escape("# <PACKAGE_LIST_MARKER>"), $packageBlock
    if ($content -notmatch "# <URL_INSTALL_MARKER>") {
        [System.Windows.MessageBox]::Show("URL install marker not found in template.", "Error", "OK", "Error")
        return
    }
    $content = $content -replace [Regex]::Escape("# <URL_INSTALL_MARKER>"), $urlBlock
    
    # Replace new markers if they exist
    if ($content -match "# <FILE_OPS_MARKER>") {
        $content = $content -replace [Regex]::Escape("# <FILE_OPS_MARKER>"), $fileOpsBlock
    }
    if ($content -match "# <NETWORK_MARKER>") {
        $content = $content -replace [Regex]::Escape("# <NETWORK_MARKER>"), $networkBlock
    }
    if ($content -match "# <COMMANDS_MARKER>") {
        $content = $content -replace [Regex]::Escape("# <COMMANDS_MARKER>"), $commandsBlock
    }

    $map = @{
        "ENABLE_CHOCOLATEY_INSTALL" = (ConvertTo-BoolString $enableChocoInstall.IsChecked)
        "ENABLE_WINGET_INSTALL" = (ConvertTo-BoolString $enableWingetInstall.IsChecked)
        "ENABLE_SCOOP_INSTALL" = (ConvertTo-BoolString $enableScoopInstall.IsChecked)
        "ENABLE_VCREDIST_INSTALL" = (ConvertTo-BoolString $enableVCRedist.IsChecked)
        "VCREDIST_URL" = $vcUrlBox.Text
        "VCREDIST_ARGS" = $vcArgsBox.Text
        "ENABLE_DXSETUP_INSTALL" = (ConvertTo-BoolString $enableDxSetup.IsChecked)
        "DXSETUP_URL" = $dxUrlBox.Text
        "ENABLE_CLEANUP" = (ConvertTo-BoolString $enableCleanup.IsChecked)
        "ENABLE_LOG" = (ConvertTo-BoolString $enableLog.IsChecked)
    }

    $content = Expand-PlaceholderText -Content $content -Map $map
    $content | Out-File -FilePath $outputBox.Text -Encoding UTF8

    [System.Windows.MessageBox]::Show("Selesai! File setup kamu sudah siap.", "Success", "OK", "Information")
})

$window.ShowDialog() | Out-Null