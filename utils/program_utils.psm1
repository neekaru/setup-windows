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

function Get-ProgramInstallationStatus {
    param (
        [string[]]$ProgramNames
    )

    $installedPrograms = @{}
    foreach ($name in $ProgramNames) {
        $installedPrograms[$name] = Test-ProgramInstalled -ProgramName $name
    }
    return $installedPrograms
}

function Test-ProgramNameExclusion {
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

function ConvertTo-NormalizedPath {
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

function Get-InstalledProgram {
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

            if (Test-ProgramNameExclusion -Name $displayName -ExcludeKeywords $ExcludeKeywords -AllowKeywords $AllowKeywords) {
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

            $normalizedPath = ConvertTo-NormalizedPath -Path $path -SystemRoot $systemRoot
            if (-not $normalizedPath) {
                continue
            }

            $files = Get-ChildItem -Path (Join-Path $normalizedPath '*') -File -Include $executableExtensions -ErrorAction SilentlyContinue
            foreach ($file in $files) {
                $programName = $file.BaseName
                if (Test-ProgramNameExclusion -Name $programName -ExcludeKeywords $ExcludeKeywords -AllowKeywords $AllowKeywords) {
                    continue
                }

                $installedPrograms.Add($programName) | Out-Null
            }
        }
    }

    $filteredResults = $installedPrograms | Where-Object { -not (Test-ProgramNameExclusion -Name $_ -ExcludeKeywords $ExcludeKeywords -AllowKeywords $AllowKeywords) } | Sort-Object
    return $filteredResults
}

# this function as wrapper for powershell, command prompt
function Invoke-Command {
    param (
        [Parameter(Mandatory)]
        [string[]]$Commands,

        [string]$Shell = 'powershell',

        [switch]$WaitForExit,

        [ValidateSet('Never', 'Retry', 'Force')]
        [string]$ConhostMode = 'Never'
    )

    $isWindowsTerminal = -not [string]::IsNullOrWhiteSpace($env:WT_SESSION)
    $shouldRetryInConhost = $ConhostMode -eq 'Retry'
    $forceConhost = $ConhostMode -eq 'Force'

    foreach ($command in $Commands) {
        if ($Shell -ieq 'powershell') {
            Write-Output "Running PowerShell command: $command"
            if ($WaitForExit) {
                if ($forceConhost) {
                    $argsList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', $command)
                    $proc = Start-Process -FilePath 'powershell' -ArgumentList $argsList -PassThru -Wait
                    $exitCode = $proc.ExitCode
                    if ($exitCode -ne 0) {
                        Write-Warning "Command failed with exit code $exitCode."
                    }
                } else {
                    powershell -NoProfile -ExecutionPolicy Bypass -Command $command
                    $exitCode = $LASTEXITCODE
                    if ($exitCode -ne 0) {
                        Write-Warning "Command failed with exit code $exitCode."
                    }
                    if ($isWindowsTerminal -and $exitCode -ne 0 -and $shouldRetryInConhost) {
                        Write-Warning "Retrying command in conhost..."
                        $argsList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', $command)
                        $proc = Start-Process -FilePath 'powershell' -ArgumentList $argsList -PassThru -Wait
                        $exitCode = $proc.ExitCode
                        if ($exitCode -ne 0) {
                            Write-Warning "Command failed in conhost with exit code $exitCode."
                        }
                    }
                }
            } else {
                if ($forceConhost) {
                    Start-Process -FilePath 'powershell' -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', $command)
                } else {
                    Start-Process -FilePath 'powershell' -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', $command) -NoNewWindow
                }
            }
        } elseif ($Shell -ieq 'cmd' -or $Shell -ieq 'cmd.exe') {
            Write-Output "Running CMD command: $command"
            if ($WaitForExit) {
                if ($forceConhost) {
                    $proc = Start-Process -FilePath 'cmd.exe' -ArgumentList @('/c', $command) -PassThru -Wait
                    $exitCode = $proc.ExitCode
                    if ($exitCode -ne 0) {
                        Write-Warning "Command failed with exit code $exitCode."
                    }
                } else {
                    cmd.exe /c $command
                    $exitCode = $LASTEXITCODE
                    if ($exitCode -ne 0) {
                        Write-Warning "Command failed with exit code $exitCode."
                    }
                    if ($isWindowsTerminal -and $exitCode -ne 0 -and $shouldRetryInConhost) {
                        Write-Warning "Retrying command in conhost..."
                        $proc = Start-Process -FilePath 'cmd.exe' -ArgumentList @('/c', $command) -PassThru -Wait
                        $exitCode = $proc.ExitCode
                        if ($exitCode -ne 0) {
                            Write-Warning "Command failed in conhost with exit code $exitCode."
                        }
                    }
                }
            } else {
                if ($forceConhost) {
                    Start-Process -FilePath 'cmd.exe' -ArgumentList @('/c', $command)
                } else {
                    Start-Process -FilePath 'cmd.exe' -ArgumentList @('/c', $command) -NoNewWindow
                }
            }
        } else {
            Write-Warning "Unsupported shell type: $Shell. Skipping command: $command"
        }
    }
}

# Export functions
Export-ModuleMember -Function Test-ProgramInstalled, Get-ProgramInstallationStatus, Get-InstalledProgram, Invoke-Command

# Create aliases for backward compatibility and common alternative names
New-Alias -Name Check-ProgramInstalled -Value Test-ProgramInstalled
New-Alias -Name Test-ProgramExists -Value Test-ProgramInstalled
New-Alias -Name Get-InstalledPrograms -Value Get-InstalledProgram
New-Alias -Name List-InstalledPrograms -Value Get-InstalledProgram
New-Alias -Name Run-Command -Value Invoke-Command
New-Alias -Name Run-Commands -Value Invoke-Command

# Export aliases
Export-ModuleMember -Alias Check-ProgramInstalled, Test-ProgramExists, Get-InstalledPrograms, List-InstalledPrograms, Run-Command, Run-Commands
