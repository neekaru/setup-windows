# Check administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

# Get config values early
$EnableScoopInstall = ${ENABLE_SCOOP_INSTALL}

# ============================================================================
# PHASE 1: User-mode operations (Scoop installation + Scoop packages)
# ============================================================================
if (-not $isAdmin -and $EnableScoopInstall) {
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "PHASE 1: USER MODE - Scoop Operations" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Import only necessary modules for Scoop
    Import-Module (Join-Path $PSScriptRoot "utils\download_utils.psm1") -Force
    Import-Module (Join-Path $PSScriptRoot "utils\execution.psm1") -Force
    Import-Module (Join-Path $PSScriptRoot "utils\soft.psm1") -Force
    
    # Install Scoop binary if not already installed
    if (!(Get-Command scoop -ErrorAction SilentlyContinue)) {
        Write-Output "Installing Scoop package manager..."
        Install-ScoopBinary
        
        # Refresh environment to get Scoop path
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "User") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    } else {
        Write-Output "Scoop is already installed."
    }
    
    # Install all Scoop packages now (before elevating)
    Write-Host "`nInstalling Scoop packages..." -ForegroundColor Cyan
    
    # <SCOOP_PACKAGES_MARKER> - Scoop packages will be inserted here by GUI
    
    Write-Host "`nAll Scoop operations complete!" -ForegroundColor Green
    Write-Host "Now elevating to ADMINISTRATOR for remaining installations..." -ForegroundColor Yellow
    Write-Host "Press any key to continue..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    # Re-launch this script as administrator
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# ============================================================================
# PHASE 2: Administrator-mode operations (Chocolatey, WinGet, system tasks)
# ============================================================================
if ($isAdmin) {
    Write-Host "============================================" -ForegroundColor Yellow
    Write-Host "PHASE 2: ADMINISTRATOR MODE - System Setup" -ForegroundColor Yellow
    Write-Host "============================================" -ForegroundColor Yellow
    Write-Host ""
}

# ------------------------------------------------------------------------------
# User-configurable placeholders (filled by GUI generator)
# ------------------------------------------------------------------------------
$EnableChocolateyInstall = ${ENABLE_CHOCOLATEY_INSTALL}
$EnableWingetInstall = ${ENABLE_WINGET_INSTALL}
$EnableScoopInstall = ${ENABLE_SCOOP_INSTALL}

$EnableVCRedistInstall = ${ENABLE_VCREDIST_INSTALL}
$VcRedistUrl = "${VCREDIST_URL}"
$VcRedistArgs = "${VCREDIST_ARGS}"
$EnableDxSetupInstall = ${ENABLE_DXSETUP_INSTALL}
$DxSetupUrl = "${DXSETUP_URL}"

$EnableCleanup = ${ENABLE_CLEANUP}
$EnableLog = ${ENABLE_LOG}
$LogFilePath = Join-Path ([Environment]::GetFolderPath("Desktop")) ("software_installation_log_{0}.txt" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

# ------------------------------------------------------------------------------
# Helper functions
# ------------------------------------------------------------------------------
function ConvertTo-List {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return @() }
    return $Value -split ";" | ForEach-Object { $_.Trim() } | Where-Object { $_ }
}

# Import utility modules
Import-Module (Join-Path $PSScriptRoot "utils\download_utils.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "utils\programs.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "utils\file.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "utils\network.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "utils\program_utils.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "utils\execution.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "utils\soft.psm1") -Force

# Package manager wrappers (allow optional -Version)
function Install-WithWinget {
    param([string]$PackageName, [string]$Version)
    
    try {
        if ($Version) {
            winget install --id $PackageName -v $Version --silent --accept-package-agreements --accept-source-agreements
        } else {
            winget install --id $PackageName --silent --accept-package-agreements --accept-source-agreements
        }
    } catch {
        # If hash mismatch occurs, retry with --force flag
        Write-Warning "Installation failed for $PackageName. Retrying with --force flag to bypass hash check..."
        if ($Version) {
            winget install --id $PackageName -v $Version --silent --accept-package-agreements --accept-source-agreements --force
        } else {
            winget install --id $PackageName --silent --accept-package-agreements --accept-source-agreements --force
        }
    }
}

function Install-WithChocolatey {
    param([string]$PackageName, [string]$Version)
    if ($Version) {
        choco install $PackageName --version $Version -y
    } else {
        choco install $PackageName -y
    }
}

function Install-WithScoop {
    param([string]$PackageName)
    scoop install $PackageName
}

# Function to clean temporary and cache folders
function Clear-SystemCache {
    Write-Output "Starting system cleanup..."
    
    # Array of paths to clean
    $cleanupPaths = @(
        "$env:TEMP",
        "$env:SystemRoot\Temp",
        "$env:USERPROFILE\AppData\Local\Temp",
        "$env:USERPROFILE\AppData\Local\Microsoft\Windows\INetCache",
        "$env:USERPROFILE\AppData\Local\Microsoft\Windows\Temporary Internet Files",
        "$env:USERPROFILE\AppData\Local\Microsoft\Windows\Explorer\IconCache*"
    )

    foreach ($path in $cleanupPaths) {
        if (Test-Path $path) {
            Write-Output "Cleaning: $path"
            try {
                Get-ChildItem -Path $path -File -Recurse -Force -ErrorAction SilentlyContinue |
                    Remove-Item -Force -ErrorAction SilentlyContinue
                Get-ChildItem -Path $path -Directory -Recurse -Force -ErrorAction SilentlyContinue |
                    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            }
            catch {
                Write-Output "Error cleaning $path : $_"
            }
        }
    }

    # Clear DNS Cache
    Write-Output "Clearing DNS Cache..."
    ipconfig /flushdns

    # Clear Windows Store Cache
    Write-Output "Clearing Windows Store Cache..."
    wsreset.exe

    # Clear Thumbnail Cache
    Write-Output "Clearing Thumbnail Cache..."
    Remove-Item "$env:USERPROFILE\AppData\Local\Microsoft\Windows\Explorer\thumbcache_*.db" -Force -ErrorAction SilentlyContinue

    Write-Output "System cleanup completed!"
}

# ============================================================================
# Package Manager Installations (Admin-only)
# ============================================================================

# Install Chocolatey
if ($EnableChocolateyInstall) {
    Write-Output "Installing Chocolatey..."
    Install-ChocolateyBinary
}

# Install WinGet if not present
if ($EnableWingetInstall) {
    Write-Output "Checking WinGet installation..."
    if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
        Install-WingetBinary -ForceInstall $false -ConhostMode 'Never' -IgnoreHashMismatch $true
    }
}

# ============================================================================
# Package Installations (Chocolatey and WinGet only - Scoop done in Phase 1)
# ============================================================================

# <PACKAGE_LIST_MARKER>

# URL installs generated by GUI
# <URL_INSTALL_MARKER>

# File operations generated by GUI
# <FILE_OPS_MARKER>

# Network tools generated by GUI
# <NETWORK_MARKER>

# Custom commands generated by GUI
# <COMMANDS_MARKER>

# Install Visual C++ Redistributables
if ($EnableVCRedistInstall) {
    Invoke-DownloadFile -Url $VcRedistUrl -OutputPath "$env:TEMP\VisualCppRedist_AIO_x86_x64.exe"
    Install-SoftwareManually -InstallerPath "$env:TEMP\VisualCppRedist_AIO_x86_x64.exe" -Arguments (ConvertTo-List $VcRedistArgs) -Wait
}

if ($EnableDxSetupInstall) {
    Invoke-DownloadFile -Url $DxSetupUrl -OutputPath "$env:TEMP\dxwebsetup.exe"
    Install-SoftwareManually -InstallerPath "$env:TEMP\dxwebsetup.exe" -Arguments @() -Wait
}

# Clean up system after installations
if ($EnableCleanup) {
    Clear-SystemCache
}

Write-Output "Installation and cleanup complete!"

# Optional: Create a log file
if ($EnableLog) {
    $logContent = @"
Installation and cleanup completed on $(Get-Date)

Installed software:
$( ($installedSoftware | ForEach-Object { "- $_" }) -join "`r`n" )

System cleanup performed:
- Temporary files removed
- DNS cache flushed
- Windows Store cache reset
- Thumbnail cache cleared
"@

    $logContent | Out-File $LogFilePath
    Write-Output "Log file created: $LogFilePath"
}

