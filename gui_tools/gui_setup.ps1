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
$templateBtn = $window.FindName("TemplateBrowseButton")
$outputBtn = $window.FindName("OutputBrowseButton")
$addRowBtn = $window.FindName("AddRowButton")
$removeRowBtn = $window.FindName("RemoveRowButton")
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

function Set-PlaceholderText {
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

function ConvertTo-BoolString([bool]$b) {
    if ($b) { return '$true' }
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
        [string]$OutputPath = "",
        [string]$InstallArgs = "",
        [bool]$RemoveInstaller = $false
    )
    if ($PSCmdlet.ShouldProcess($Name, "Create URL install row")) {
        [PSCustomObject]@{
            Enabled = $Enabled
            Name = $Name
            Url = $Url
            OutputPath = $OutputPath
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
        if ([string]::IsNullOrWhiteSpace($item.OutputPath)) { continue }

        $url = ConvertTo-PowerShellString $item.Url
        $out = ConvertTo-PowerShellString $item.OutputPath
        $argsBlock = ""

        if (-not [string]::IsNullOrWhiteSpace($item.InstallArgs)) {
            $argList = $item.InstallArgs -split ";" | ForEach-Object { $_.Trim() } | Where-Object { $_ }
            if ($argList.Count -gt 0) {
                $argItems = $argList | ForEach-Object { "`"$((ConvertTo-PowerShellString $_))`"" }
                $argsBlock = " -InstallArguments @($($argItems -join ", "))"
            }
        }

        $removeFlag = ""
        if ($item.RemoveInstaller) { $removeFlag = " -RemoveInstaller" }

        $lines.Add("Install-SoftwareFromUrl -Url `"$url`" -OutputPath `"$out`"$argsBlock$removeFlag")
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

if (Test-Path $urlListPath) {
    try {
        $json = Get-Content -Raw -Path $urlListPath | ConvertFrom-Json
        foreach ($item in $json) {
            $urlItems.Add((
                New-UrlRow `
                    -Enabled ($item.Enabled -ne $false) `
                    -Name $item.Name `
                    -Url $item.Url `
                    -OutputPath $item.OutputPath `
                    -InstallArgs $item.InstallArgs `
                    -RemoveInstaller ([bool]$item.RemoveInstaller)
            ))
        }
    } catch {
        $urlItems.Add((New-UrlRow -Name "PostgreSQL" -Url "https://get.enterprisedb.com/postgresql/postgresql-17.3-1-windows-x64.exe" -OutputPath "$env:TEMP\\postgresql-17.3-1-windows-x64.exe"))
        $urlItems.Add((New-UrlRow -Name "IDM" -Url "https://download.internetdownloadmanager.com/idman641build2.exe" -OutputPath "$env:TEMP\\idm_installer.exe" -InstallArgs "/silent" -RemoveInstaller $true))
    }
} else {
    $urlItems.Add((New-UrlRow -Name "PostgreSQL" -Url "https://get.enterprisedb.com/postgresql/postgresql-17.3-1-windows-x64.exe" -OutputPath "$env:TEMP\\postgresql-17.3-1-windows-x64.exe"))
    $urlItems.Add((New-UrlRow -Name "IDM" -Url "https://download.internetdownloadmanager.com/idman641build2.exe" -OutputPath "$env:TEMP\\idm_installer.exe" -InstallArgs "/silent" -RemoveInstaller $true))
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
    if ($urlGrid.IsVisible) { return @{ Grid = $urlGrid; Items = $urlItems; RowFactory = { New-UrlRow -Enabled $true -Name "" -Url "" -OutputPath "" -InstallArgs "" -RemoveInstaller $false } } }
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

    $map = @{
        "ENABLE_CHOCOLATEY_INSTALL" = (ConvertTo-BoolString [bool]$enableChocoInstall.IsChecked)
        "ENABLE_WINGET_INSTALL" = (ConvertTo-BoolString [bool]$enableWingetInstall.IsChecked)
        "ENABLE_SCOOP_INSTALL" = (ConvertTo-BoolString [bool]$enableScoopInstall.IsChecked)
        "ENABLE_VCREDIST_INSTALL" = (ConvertTo-BoolString [bool]$enableVCRedist.IsChecked)
        "VCREDIST_URL" = $vcUrlBox.Text
        "VCREDIST_ARGS" = $vcArgsBox.Text
        "ENABLE_DXSETUP_INSTALL" = (ConvertTo-BoolString [bool]$enableDxSetup.IsChecked)
        "DXSETUP_URL" = $dxUrlBox.Text
        "ENABLE_CLEANUP" = (ConvertTo-BoolString [bool]$enableCleanup.IsChecked)
        "ENABLE_LOG" = (ConvertTo-BoolString [bool]$enableLog.IsChecked)
    }

    $content = Set-PlaceholderText -Content $content -Map $map
    $content | Out-File -FilePath $outputBox.Text -Encoding UTF8

    [System.Windows.MessageBox]::Show("Selesai! File setup kamu sudah siap.", "Success", "OK", "Information")
})

$window.ShowDialog() | Out-Null
