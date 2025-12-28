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
    param(
        [System.Collections.IEnumerable]$Items,
        [string[]]$Blacklist = @()
    )
    $lines = New-Object System.Collections.Generic.List[string]

    foreach ($item in $Items) {
        if (-not $item.Enabled) { continue }
        if ([string]::IsNullOrWhiteSpace($item.Url)) { continue }
        if ([string]::IsNullOrWhiteSpace($item.Filename)) { continue }

        # Check blacklist
        $skip = $false
        foreach ($bl in $Blacklist) {
            if ($item.Name -match $bl -or $item.Url -match $bl -or $item.Filename -match $bl) {
                $skip = $true
                break
            }
        }
        if ($skip) { continue }

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
        [System.Collections.IEnumerable]$ScoopItems,
        [switch]$ScoopOnly,
        [string[]]$Blacklist = @()
    )
    $lines = New-Object System.Collections.Generic.List[string]

    if ($ScoopOnly) {
        foreach ($item in $ScoopItems) {
            if (-not $item.Enabled) { continue }
            if ([string]::IsNullOrWhiteSpace($item.PackageName)) { continue }

            # RAW
            $nameRaw = [string]$item.PackageName

            # Trim + buang bullet "- " / "* "
            $nameRaw = ($nameRaw -replace '^\s*[\-\*]\s*', '').Trim()

            # Skip token/token aneh
            if ([string]::IsNullOrWhiteSpace($nameRaw)) { continue }
            if ($nameRaw -eq '-' -or $nameRaw -eq '--') { continue }

            # Jangan pernah install "scoop" sebagai package (itu core)
            if ($nameRaw.Trim().ToLowerInvariant() -eq 'scoop') { continue }

            # Apply blacklist juga untuk scoop (biar konsisten)
            $skip = $false
            foreach ($bl in $Blacklist) {
                if ($nameRaw -match $bl) { $skip = $true; break }
            }
            if ($skip) { continue }

            # Version (opsional) -> "app@version"
            $spec = ConvertTo-PowerShellString $nameRaw
            if (-not [string]::IsNullOrWhiteSpace($item.Version)) {
                $verRaw = [string]$item.Version
                $verRaw = $verRaw.Trim()
                if ($verRaw) {
                    $ver = ConvertTo-PowerShellString $verRaw
                    $spec = "$spec@$ver"
                }
            }

            $lines.Add("scoop install $spec")
        }

        if ($lines.Count -eq 0) { return "# (no Scoop packages selected)" }
        return ($lines -join "`r`n")
    }

    # Generate WinGet and Chocolatey installations (for Phase 2 - admin mode)
    foreach ($item in $WingetItems) {
        if (-not $item.Enabled) { continue }
        if ([string]::IsNullOrWhiteSpace($item.PackageName)) { continue }
        
        # Check blacklist
        $skip = $false
        foreach ($bl in $Blacklist) {
            if ($item.PackageName -match $bl) { $skip = $true; break }
        }
        if ($skip) { continue }

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

        # Check blacklist
        $skip = $false
        foreach ($bl in $Blacklist) {
            if ($item.PackageName -match $bl) { $skip = $true; break }
        }
        if ($skip) { continue }

        $name = ConvertTo-PowerShellString $item.PackageName
        if ([string]::IsNullOrWhiteSpace($item.Version)) {
            $lines.Add("Install-WithChocolatey -PackageName `"$name`"")
        } else {
            $ver = ConvertTo-PowerShellString $item.Version
            $lines.Add("Install-WithChocolatey -PackageName `"$name`" -Version `"$ver`"")
        }
    }

    if ($lines.Count -eq 0) {
        return "# (no Chocolatey or WinGet packages selected)"
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
    
    # Define blacklist if Scoop is enabled
    $blacklist = if ($enableScoopInstall.IsChecked) {
        @("^(?i)scoop$", "^\-$", "^\-\-$", "7zip", "7-zip", "7zip\.7zip")
    } else {
        @()
    }

    # Generate installation blocks
    $scoopPackagesBlock = Get-PackageCommand -ScoopItems $scoopItems -ScoopOnly
    $packageBlock = Get-PackageCommand -WingetItems $wingetItems -ChocoItems $chocoItems -ScoopItems $scoopItems -Blacklist $blacklist
    $urlBlock = Get-UrlInstallCommand -Items $urlItems -Blacklist $blacklist
    $fileOpsBlock = Get-FileOpsCommand -Items $fileOpsItems
    $networkBlock = Get-NetworkCommand -Items $networkItems
    $commandsBlock = Get-CommandsCommand -Items $commandsItems

    # Replace Scoop packages marker (Phase 1 - user mode)
    if ($content -notmatch "# <SCOOP_PACKAGES_MARKER>") {
        [System.Windows.MessageBox]::Show("Scoop packages marker not found in template.", "Error", "OK", "Error")
        return
    }
    $content = $content -replace [Regex]::Escape("# <SCOOP_PACKAGES_MARKER>"), $scoopPackagesBlock

    # Replace main package list marker (Phase 2 - admin mode, Chocolatey and WinGet only)
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

    # Create deployment package
    $outputDir = Split-Path $outputBox.Text
    $outputName = [System.IO.Path]::GetFileNameWithoutExtension($outputBox.Text)
    $zipPath = Join-Path $outputDir "$outputName-package.zip"
    $batPath = Join-Path $outputDir "install.bat"
    
    try {
        # Remove old zip if exists
        if (Test-Path $zipPath) {
            Remove-Item $zipPath -Force
        }
        
        # Create temporary staging directory
        $stagingDir = Join-Path $env:TEMP "setup-package-$(Get-Date -Format 'yyyyMMddHHmmss')"
        New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null
        
        # Save setup.ps1 to staging (not to output directory)
        $content | Out-File -FilePath (Join-Path $stagingDir "setup.ps1") -Encoding UTF8
        
        # Copy utils folder to staging
        $utilsSource = Join-Path $projectRoot "utils"
        $utilsDest = Join-Path $stagingDir "utils"
        if (Test-Path $utilsSource) {
            Copy-Item $utilsSource -Destination $utilsDest -Recurse -Force
        }
        
        # Create bin folder and download aria2c.exe for faster downloads
        $binDir = Join-Path $stagingDir "bin"
        New-Item -ItemType Directory -Path $binDir -Force | Out-Null
        
        $aria2Url = "https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip"
        $aria2Zip = Join-Path $env:TEMP "aria2_temp.zip"
        $aria2ExtractDir = Join-Path $env:TEMP "aria2_extract"
        
        try {
            Write-Host "Downloading aria2c.exe for package..." -ForegroundColor Cyan
            Invoke-WebRequest -Uri $aria2Url -OutFile $aria2Zip -UseBasicParsing
            
            # Extract and copy only aria2c.exe to bin folder
            Expand-Archive -Path $aria2Zip -DestinationPath $aria2ExtractDir -Force
            $aria2Exe = Get-ChildItem -Path $aria2ExtractDir -Recurse -Filter "aria2c.exe" | Select-Object -First 1
            if ($aria2Exe) {
                Copy-Item $aria2Exe.FullName -Destination (Join-Path $binDir "aria2c.exe") -Force
                Write-Host "aria2c.exe added to bin folder" -ForegroundColor Green
            }
            
            # Cleanup temp files
            Remove-Item $aria2Zip -Force -ErrorAction SilentlyContinue
            Remove-Item $aria2ExtractDir -Recurse -Force -ErrorAction SilentlyContinue
        } catch {
            Write-Warning "Failed to download aria2c: $_. Package will use PowerShell downloader instead."
        }
        
        # Create zip file
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::CreateFromDirectory($stagingDir, $zipPath)
        
        # Clean up staging directory
        Remove-Item $stagingDir -Recurse -Force
        
        # Create install.bat
        $batContent = @"
@echo off
REM Disable QuickEdit Mode to prevent accidental pauses
reg add "HKCU\Console" /v QuickEdit /t REG_DWORD /d 0 /f >nul

echo ================================================
echo   Windows Setup Installation Package
echo ================================================
echo.
echo Extracting files...

REM Get the directory where this batch file is located
set SCRIPT_DIR=%~dp0

REM Extract the zip file
powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%SCRIPT_DIR%$outputName-package.zip' -DestinationPath '%SCRIPT_DIR%extracted' -Force"
if %errorlevel% neq 0 goto ERROR

echo.
echo Running setup script...
echo.

REM Run the setup script as administrator
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%SCRIPT_DIR%extracted\setup.ps1""' -Verb RunAs"
if %errorlevel% neq 0 goto ERROR

echo.
echo Installation started. Check the elevated PowerShell window.
goto END

:ERROR
REM Re-enable QuickEdit Mode on error
reg add "HKCU\Console" /v QuickEdit /t REG_DWORD /d 1 /f >nul
echo.
echo [ERROR] An error occurred during the installation process.
pause

:END
echo.
pause
"@
        
        $batContent | Out-File -FilePath $batPath -Encoding ASCII
        
        [System.Windows.MessageBox]::Show("Selesai! File setup kamu sudah siap.`n`nFiles created:`n- $outputName-package.zip`n- install.bat`n`nJust copy both files to distribute!", "Success", "OK", "Information")
    }
    catch {
        [System.Windows.MessageBox]::Show("Package creation failed: $_", "Error", "OK", "Error")
    }
})

$window.ShowDialog() | Out-Null