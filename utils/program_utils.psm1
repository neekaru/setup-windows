# this for utils to check if programs are installed

function Test-ProgramInstalled {
    param (
        [string]$ProgramName
    )

    $program = Get-Command $ProgramName -ErrorAction SilentlyContinue
    if ($null -ne $program) {
        return $true
    } else {
        return $false
    }
}

function List-ProgramsInstalled {
    param (
        [string[]]$ProgramNames
    )

    $installedPrograms = @{}
    foreach ($name in $ProgramNames) {
        $installedPrograms[$name] = Test-ProgramInstalled -ProgramName $name
    }
    return $installedPrograms
}

function Should-ExcludeProgramName {
    param (
        [Parameter(Mandatory)]
        [string]$Name,

        [string[]]$ExcludeKeywords,
        [string[]]$AllowKeywords
    )

    $candidate = $Name.Trim()

    if ($AllowKeywords) {
        foreach ($allowKeyword in $AllowKeywords) {
            if ([string]::IsNullOrWhiteSpace($allowKeyword)) {
                continue
            }

            if ($candidate -ieq $allowKeyword.Trim()) {
                return $false
            }
        }
    }

    foreach ($keyword in $ExcludeKeywords) {
        if ([string]::IsNullOrWhiteSpace($keyword)) {
            continue
        }

        $pattern = $keyword.Trim()
        if ($pattern -notmatch '[\*\?]') {
            $pattern = "*$pattern*"
        }

        if ($candidate -ilike $pattern) {
            return $true
        }
    }

    return $false
}

function Normalize-PathEntry {
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [string]$SystemRoot
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $null
    }

    try {
        $normalized = [System.IO.Path]::GetFullPath($Path)
    } catch {
        return $null
    }

    if (-not (Test-Path $normalized)) {
        return $null
    }

    $trimmed = $normalized.TrimEnd('\','/')
    if ($SystemRoot -and $trimmed.StartsWith($SystemRoot, [System.StringComparison]::InvariantCultureIgnoreCase)) {
        return $null
    }

    if ($trimmed -match '(?i)AppData[\\/]Local[\\/]Microsoft[\\/]WindowsApps') {
        return $null
    }

    if ($trimmed -match '(?i)[\\/]Windows[\\/]System32(?:[\\/].*)?$') {
        return $null
    }

    if ($trimmed -match '(?i)(?:^|/)bin$|^[A-Za-z]:\\bin$') {
        return $null
    }

    return $trimmed
}

function Get-AllInstalledPrograms {
    param (
        [string[]]$ExcludeKeywords = @('Windows Update', 'WindowsUpdate', 'Driver', 'Service', 'PowerShell', 'pwsh', 'CORE_RL_*', 'System*', 'Windows*', 'Microsoft*'),
        [string[]]$AllowKeywords = @('System.Xml'),
        [bool]$IncludePathPrograms = $true
    )

    $registryPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )

    $installedPrograms = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)

    $systemRoot = $null
    if ($env:WINDIR) {
        try {
            $systemRoot = [System.IO.Path]::GetFullPath($env:WINDIR)
        } catch {
            $systemRoot = $null
        }
    }

    foreach ($path in $registryPaths) {
        $parentPath = Split-Path $path
        if (-not (Test-Path $parentPath)) {
            continue
        }

        $entries = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
        if ($null -eq $entries) {
            continue
        }

        foreach ($entry in $entries) {
            if ($entry.PSObject.Properties['SystemComponent'] -and [int]$entry.SystemComponent -eq 1) {
                continue
            }

            if ($entry.PSObject.Properties['ReleaseType'] -and ($entry.ReleaseType -match 'Update|Hotfix|Security')) {
                continue
            }

            if ($entry.PSObject.Properties['Publisher'] -and ($entry.Publisher -match 'Microsoft|Windows')) {
                continue
            }

            $installLocation = $null
            if ($entry.PSObject.Properties['InstallLocation'] -and -not [string]::IsNullOrWhiteSpace($entry.InstallLocation)) {
                try {
                    $installLocation = [System.IO.Path]::GetFullPath($entry.InstallLocation)
                } catch {
                    $installLocation = $entry.InstallLocation
                }
            }

            if ($systemRoot -and $installLocation -and $installLocation.StartsWith($systemRoot, [System.StringComparison]::InvariantCultureIgnoreCase)) {
                continue
            }

            $displayName = $entry.DisplayName
            if ([string]::IsNullOrWhiteSpace($displayName)) {
                continue
            }

            if (Should-ExcludeProgramName -Name $displayName -ExcludeKeywords $ExcludeKeywords -AllowKeywords $AllowKeywords) {
                continue
            }

            $installedPrograms.Add($displayName) | Out-Null
        }
    }

    if ($IncludePathPrograms) {
        $pathEntries = @()
        $pathEntries += ($env:PATH -split ';')
        $userEnvPath = (Get-ItemProperty -Path 'HKCU:\Environment' -Name Path -ErrorAction SilentlyContinue).Path
        if ($userEnvPath) {
            $pathEntries += ($userEnvPath -split ';')
        }

        $pathEntries = $pathEntries | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { [Environment]::ExpandEnvironmentVariables($_) } | Select-Object -Unique

        $executableExtensions = @('*.exe', '*.com', '*.bat', '*.cmd', '*.ps1', '*.psm1', '*.psd1', '*.msc')
        foreach ($path in $pathEntries) {
            $normalPath = $path -replace '/', '\'
            
            if ($normalPath -imatch 'AppData\\Local\\Microsoft\\WindowsApps') {
                continue
            }
            
            if ($normalPath -imatch '^[A-Za-z]:\\bin$|^[A-Za-z]:\\usr\\bin|^[A-Za-z]:\\usr\\local\\bin') {
                continue
            }
            
            if ($normalPath -imatch 'Program Files\\PowerShell') {
                continue
            }

            $normalizedPath = Normalize-PathEntry -Path $path -SystemRoot $systemRoot
            if (-not $normalizedPath) {
                continue
            }

            $files = Get-ChildItem -Path (Join-Path $normalizedPath '*') -File -Include $executableExtensions -ErrorAction SilentlyContinue
            foreach ($file in $files) {
                $programName = $file.BaseName
                if (Should-ExcludeProgramName -Name $programName -ExcludeKeywords $ExcludeKeywords -AllowKeywords $AllowKeywords) {
                    continue
                }

                $installedPrograms.Add($programName) | Out-Null
            }
        }
    }

    $filteredResults = $installedPrograms | Where-Object { -not (Should-ExcludeProgramName -Name $_ -ExcludeKeywords $ExcludeKeywords -AllowKeywords $AllowKeywords) } | Sort-Object
    return $filteredResults
}

Export-ModuleMember -Function Test-ProgramInstalled, List-ProgramsInstalled, Get-AllInstalledPrograms