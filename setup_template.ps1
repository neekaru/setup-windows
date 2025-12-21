# Requires administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as Administrator!"
    break
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
function Convert-ToList {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return @() }
    return $Value -split ";" | ForEach-Object { $_.Trim() } | Where-Object { $_ }
}

# Import utility modules
Import-Module ./utils/download.psm1 -Force
Import-Module ./utils/programs.psm1 -Force
Import-Module ./utils/file.psm1 -Force

# Package manager wrappers (allow optional -Version)
function Install-WithWinget {
    param([string]$PackageName, [string]$Version)
    if ($Version) {
        winget install --id $PackageName -v $Version --silent
    } else {
        winget install --id $PackageName --silent
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
    param([string]$PackageName, [string]$Version)
    scoop install $PackageName
}

# Function to clean temporary and cache folders
function Clear-SystemCache {
    Write-Host "Starting system cleanup..."
    
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
            Write-Host "Cleaning: $path"
            try {
                Get-ChildItem -Path $path -File -Recurse -Force -ErrorAction SilentlyContinue |
                    Remove-Item -Force -ErrorAction SilentlyContinue
                Get-ChildItem -Path $path -Directory -Recurse -Force -ErrorAction SilentlyContinue |
                    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            }
            catch {
                Write-Host "Error cleaning $path : $_"
            }
        }
    }

    # Clear DNS Cache
    Write-Host "Clearing DNS Cache..."
    ipconfig /flushdns

    # Clear Windows Store Cache
    Write-Host "Clearing Windows Store Cache..."
    wsreset.exe

    # Clear Thumbnail Cache
    Write-Host "Clearing Thumbnail Cache..."
    Remove-Item "$env:USERPROFILE\AppData\Local\Microsoft\Windows\Explorer\thumbcache_*.db" -Force -ErrorAction SilentlyContinue

    Write-Host "System cleanup completed!"
}

# Install Chocolatey
if ($EnableChocolateyInstall) {
    Write-Host "Installing Chocolatey..."
    if (!(Test-Path "$env:ProgramData\chocolatey\choco.exe")) {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }
}

# Install WinGet if not present
if ($EnableWingetInstall) {
    Write-Host "Checking WinGet installation..."
    if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "WinGet not found. Downloading Microsoft.VCLibs.140.00 and Microsoft.UI.Xaml.2.7 UWP packages..."
        $packages = @(
            "Microsoft.VCLibs.140.00_14.0.33519.0_x64__8wekyb3d8bbwe.Appx",
            "Microsoft.VCLibs.140.00_14.0.33519.0_x86__8wekyb3d8bbwe.Appx",
            "Microsoft.VCLibs.140.00.UWPDesktop_14.0.33728.0_x86__8wekyb3d8bbwe.Appx",
            "Microsoft.VCLibs.140.00.UWPDesktop_14.0.33728.0_x64__8wekyb3d8bbwe.Appx",
            "Microsoft.UI.Xaml.2.8_8.2310.30001.0_x86__8wekyb3d8bbwe.Appx",
            "Microsoft.UI.Xaml.2.8_8.2310.30001.0_x64__8wekyb3d8bbwe.Appx"
        )
        $base_url = "https://github.com/MatiDEV-PL/Open-ToolBox/raw/main/Appx/"
        foreach ($package in $packages) {
            $output_path = "$env:TEMP\$package"
            Invoke-DownloadFile -Url ($base_url + $package) -OutputPath $output_path
            Add-AppxPackage -Path $output_path
        }

        Write-Host "Installing WinGet..."
        Get-GithubReleaseAsset -repository "microsoft/winget-cli" -assetName "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -outputPath "$env:TEMP\Microsoft.DesktopAppInstaller.msixbundle"
        Add-AppxPackage -Path "$env:TEMP\Microsoft.DesktopAppInstaller.msixbundle"
    }
}

# Install Scoop if not present
if ($EnableScoopInstall) {
    Write-Host "Checking Scoop installation..."
    if (!(Get-Command scoop -ErrorAction SilentlyContinue)) {
        Write-Host "Scoop not found. Installing Scoop..."
        Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Invoke-Expression (Invoke-WebRequest -UseBasicParsing -Uri "https://get.scoop.sh").Content
    }
}

# Package list generated by GUI
# <PACKAGE_LIST_MARKER>

# URL installs generated by GUI
# <URL_INSTALL_MARKER>

# Install Visual C++ Redistributables
if ($EnableVCRedistInstall) {
    Invoke-DownloadFile -Url $VcRedistUrl -OutputPath "$env:TEMP\VisualCppRedist_AIO_x86_x64.exe"
    Install-SoftwareManually -InstallerPath "$env:TEMP\VisualCppRedist_AIO_x86_x64.exe" -Arguments (Convert-ToList $VcRedistArgs) -Wait
}

if ($EnableDxSetupInstall) {
    Invoke-DownloadFile -Url $DxSetupUrl -OutputPath "$env:TEMP\dxwebsetup.exe"
    Install-SoftwareManually -InstallerPath "$env:TEMP\dxwebsetup.exe" -Arguments @() -Wait
}

# Clean up system after installations
if ($EnableCleanup) {
    Clear-SystemCache
}

Write-Host "Installation and cleanup complete!"

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
    Write-Host "Log file created: $LogFilePath"
}
