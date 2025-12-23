# Comprehensive software installation wrapper for Chocolatey, Winget, Scoop, and direct installation
Import-Module "$PSScriptRoot/download.psm1" -Force
Import-Module "$PSScriptRoot/execution.psm1" -Force

function Test-PackageManager {
    param (
        [ValidateSet('Chocolatey', 'Winget', 'Scoop')]
        [string]$Manager
    )

    switch ($Manager) {
        'Chocolatey' {
            $chocoPath = Get-Command choco -ErrorAction SilentlyContinue
            return $null -ne $chocoPath
        }
        'Winget' {
            $wingetPath = Get-Command winget -ErrorAction SilentlyContinue
            return $null -ne $wingetPath
        }
        'Scoop' {
            $scoopPath = Get-Command scoop -ErrorAction SilentlyContinue
            return $null -ne $scoopPath
        }
    }
    return $false
}

function Get-AvailablePackageManager {
    $available = @()
    
    if (Test-PackageManager -Manager 'Chocolatey') {
        $available += 'Chocolatey'
    }
    if (Test-PackageManager -Manager 'Winget') {
        $available += 'Winget'
    }
    if (Test-PackageManager -Manager 'Scoop') {
        $available += 'Scoop'
    }
    
    return $available
}

function Install-WithChocolatey {
    param (
        [Parameter(Mandatory)]
        [string]$PackageName,

        [string]$Version,
        [string[]]$Arguments,
        [switch]$Force
    )

    try {
        if (-not (Test-PackageManager -Manager 'Chocolatey')) {
            Write-Error "Chocolatey is not installed or not in PATH"
            return $false
        }

        Write-Verbose "Installing with Chocolatey: $PackageName"

        $chocoArgs = @('install', $PackageName, '-y')

        if ($Version) {
            $chocoArgs += @('--version', $Version)
        }

        if ($Force) {
            $chocoArgs += '--force'
        }

        if ($Arguments) {
            $chocoArgs += @('--install-arguments', ($Arguments -join ' '))
        }

        & choco @chocoArgs

        if ($LASTEXITCODE -eq 0) {
            Write-Verbose "Successfully installed $PackageName with Chocolatey"
            return $true
        } else {
            Write-Error "Chocolatey installation failed with exit code: $LASTEXITCODE"
            return $false
        }
    } catch {
        Write-Error "Failed to install with Chocolatey: $_"
        return $false
    }
}

function Install-WithWinget {
    param (
        [Parameter(Mandatory)]
        [string]$PackageName,

        [string]$Version,
        [string[]]$Arguments,
        [switch]$Silent
    )

    try {
        if (-not (Test-PackageManager -Manager 'Winget')) {
            Write-Error "Winget is not installed or not in PATH"
            return $false
        }

        Write-Verbose "Installing with Winget: $PackageName"

        $wingetArgs = @('install', '--id', $PackageName, '-e', '-h')

        if ($Silent) {
            $wingetArgs += '--silent'
        }

        if ($Version) {
            $wingetArgs += @('-v', $Version)
        }

        if ($Arguments) {
            $wingetArgs += @('--override', ($Arguments -join ' '))
        }

        & winget @wingetArgs

        if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 0x80070666) {  # 0 = success, 0x80070666 = already installed
            Write-Verbose "Successfully installed $PackageName with Winget"
            return $true
        } else {
            Write-Error "Winget installation failed with exit code: $LASTEXITCODE"
            return $false
        }
    } catch {
        Write-Error "Failed to install with Winget: $_"
        return $false
    }
}

function Install-WithScoop {
    param (
        [Parameter(Mandatory)]
        [string]$PackageName,

        [string]$Bucket,
        [switch]$Global
    )

    try {
        if (-not (Test-PackageManager -Manager 'Scoop')) {
            Write-Error "Scoop is not installed or not in PATH"
            return $false
        }

        Write-Verbose "Installing with Scoop: $PackageName"

        $scoopArgs = @('install', $PackageName)

        if ($Global) {
            $scoopArgs += '-g'
        }

        if ($Bucket) {
            $scoopArgs += @('-b', $Bucket)
        }

        & scoop @scoopArgs

        if ($LASTEXITCODE -eq 0) {
            Write-Verbose "Successfully installed $PackageName with Scoop"
            return $true
        } else {
            Write-Error "Scoop installation failed with exit code: $LASTEXITCODE"
            return $false
        }
    } catch {
        Write-Error "Failed to install with Scoop: $_"
        return $false
    }
}

function Install-SoftwareFromUrl {
    param (
        [Parameter(Mandatory)]
        [string]$Url,

        [Parameter(Mandatory)]
        [string]$OutputPath,

        [string[]]$InstallArguments,
        [int]$TimeoutSeconds = 300,
        [switch]$RemoveInstaller,
        [switch]$Silent
    )

    try {
        Write-Verbose "Installing software from URL"
        Write-Verbose "URL: $Url"
        Write-Verbose "Output: $OutputPath"

        # Import downloader module if available
        $downloadModule = Get-Module -Name download -ErrorAction SilentlyContinue
        if (-not $downloadModule) {
            Import-Module ./utils/download.psm1 -ErrorAction SilentlyContinue
        }

        # Download the file
        Write-Verbose "Downloading installer..."
        $downloadSuccess = Invoke-DownloadFile -Url $Url -OutputPath $OutputPath -TimeoutSeconds $TimeoutSeconds
        
        if (-not $downloadSuccess) {
            Write-Error "Failed to download installer"
            return $false
        }

        if (-not (Test-Path $OutputPath)) {
            Write-Error "Downloaded file not found: $OutputPath"
            return $false
        }

        $installerFile = Get-Item $OutputPath
        Write-Verbose "Downloaded: $($installerFile.Name) ($($installerFile.Length) bytes)"

        # Execute installer
        Write-Verbose "Executing installer..."
        $processArgs = @{
            FilePath = $OutputPath
            Wait = $true
            NoNewWindow = $Silent
        }

        if ($InstallArguments) {
            $processArgs['ArgumentList'] = $InstallArguments
            Write-Verbose "Install arguments: $($InstallArguments -join ' ')"
        }

        $process = Start-Process @processArgs -PassThru
        $exitCode = $process.ExitCode

        if ($exitCode -eq 0) {
            Write-Verbose "Software installed successfully"
            
            if ($RemoveInstaller) {
                Remove-Item $OutputPath -Force -ErrorAction SilentlyContinue
                Write-Verbose "Installer removed: $OutputPath"
            }
            
            return $true
        } else {
            Write-Error "Installer failed with exit code: $exitCode"
            return $false
        }
    } catch {
        Write-Error "Failed to install software from URL: $_"
        return $false
    }
}

function Install-SoftwareManually {
    param (
        [Parameter(Mandatory)]
        [string]$InstallerPath,

        [string[]]$Arguments,
        [switch]$Wait,
        [switch]$NoWindow,
        [switch]$Silent
    )

    try {
        if (-not (Test-Path $InstallerPath)) {
            Write-Error "Installer file not found: $InstallerPath"
            return $false
        }

        $installerFile = Get-Item $InstallerPath
        Write-Verbose "Running installer: $($installerFile.Name)"
        Write-Verbose "Path: $InstallerPath"

        if ($Arguments) {
            Write-Verbose "Arguments: $($Arguments -join ' ')"
        }

        $processArgs = @{
            FilePath = $InstallerPath
            Wait = $Wait
            NoNewWindow = if ($Silent) { $true } else { $NoWindow }
        }

        if ($Arguments) {
            $processArgs['ArgumentList'] = $Arguments
        }

        $process = Start-Process @processArgs -PassThru
        
        if ($Wait) {
            $exitCode = $process.ExitCode
            if ($exitCode -eq 0) {
                Write-Verbose "Installer completed successfully"
                return $true
            } else {
                Write-Warning "Installer exited with code: $exitCode"
                return $true  # Return true since installer ran, just may have non-zero exit code
            }
        } else {
            Write-Verbose "Installer started with PID: $($process.Id)"
            return $true
        }
    } catch {
        Write-Error "Failed to run installer manually: $_"
        return $false
    }
}

function Get-SoftwareInstallationInfo {
    $info = @{
        AvailableManagers = Get-AvailablePackageManager
        Chocolatey = @{
            Available = Test-PackageManager -Manager 'Chocolatey'
            Version = if (Test-PackageManager -Manager 'Chocolatey') { 
                (choco --version 2>$null) 
            } else { 
                'Not installed' 
            }
        }
        Winget = @{
            Available = Test-PackageManager -Manager 'Winget'
            Version = if (Test-PackageManager -Manager 'Winget') { 
                (winget --version 2>$null) 
            } else { 
                'Not installed' 
            }
        }
        Scoop = @{
            Available = Test-PackageManager -Manager 'Scoop'
            Version = if (Test-PackageManager -Manager 'Scoop') { 
                (scoop --version 2>$null) 
            } else { 
                'Not installed' 
            }
        }
    }

    return $info
}

Export-ModuleMember -Function `
    Test-PackageManager, `
    Get-AvailablePackageManager, `
    Install-WithChocolatey, `
    Install-WithWinget, `
    Install-WithScoop, `
    Install-SoftwareFromUrl, `
    Install-SoftwareManually, `
    Get-SoftwareInstallationInfo


# Create aliases for backward compatibility and common alternative names
New-Alias -Name Check-PackageManager -Value Test-PackageManager
New-Alias -Name Install-Chocolatey -Value Install-WithChocolatey
New-Alias -Name Install-Winget -Value Install-WithWinget
New-Alias -Name Install-Scoop -Value Install-WithScoop
New-Alias -Name Install-FromUrl -Value Install-SoftwareFromUrl
New-Alias -Name Install-Software -Value Install-SoftwareManually

# Export aliases
Export-ModuleMember -Alias Check-PackageManager, Install-Chocolatey, Install-Winget, Install-Scoop, Install-FromUrl, Install-Software
