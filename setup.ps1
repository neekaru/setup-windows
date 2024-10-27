# Requires administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as Administrator!"
    break
}

# Function to check if a program is installed
function Test-ProgramInstalled {
    param (
        [string]$programName
    )
    $installed = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
        Where-Object { $_.DisplayName -like "*$programName*" }
    return $null -ne $installed
}

# Function to download file
function Get-FileFromUrl {
    param (
        [string]$url,
        [string]$outputPath,
        [bool]$useIDM = $false
    )
    Write-Host "Downloading from $url..."
    if ($useIDM) {
        $idmPath = "C:\Program Files (x86)\Internet Download Manager\IDMan.exe"
        if (Test-Path $idmPath) {
            $arguments = "/d $url /p $outputPath /f $(Split-Path -Leaf $outputPath) /n /q"
            Start-Process -FilePath $idmPath -ArgumentList $arguments -Wait
            Write-Host "Download completed using IDM: $outputPath"
            return $true
        } else {
            Write-Host "IDM not found, falling back to PowerShell download."
        }
    }
    try {
        Invoke-WebRequest -Uri $url -OutFile $outputPath
        Write-Host "Download completed: $outputPath"
        return $true
    }
    catch {
        Write-Host "Failed to download: $url"
        Write-Host $_.Exception.Message
        return $false
    }
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

function Get-GithubReleaseAsset {
    param (
        [string]$repository,
        [string]$tag,
        [string]$assetName,
        [string]$outputPath
    )
    $url = "https://github.com/${repository}/releases/download/${tag}/${assetName}"
    Write-Host "Downloading ${assetName} from ${url}..."
    try {
        Invoke-WebRequest -Uri $url -OutFile $outputPath
        Write-Host "Download completed: ${outputPath}"
    }
    catch {
        Write-Host "Failed to download ${assetName}: $_" -ForegroundColor Red
    }
}

# Install Chocolatey
Write-Host "Installing Chocolatey..."
if (!(Test-Path "$env:ProgramData\chocolatey\choco.exe")) {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

# Install WinGet if not present
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
        Get-FileFromUrl -url ($base_url + $package) -outputPath $output_path
        Add-AppxPackage -Path $output_path
    }

    Write-Host "Installing WinGet..."
    Get-GithubReleaseAsset -repository "microsoft/winget-cli" -tag "latest" -assetName "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -outputPath "$env:TEMP\Microsoft.DesktopAppInstaller.msixbundle"
    Add-AppxPackage -Path "$env:TEMP\Microsoft.DesktopAppInstaller.msixbundle"
}


# Function to install software using Chocolatey
function Install-ChocoPackage {
    param (
        [string]$packageName
    )
    Write-Host "Installing $packageName using Chocolatey..."
    try {
        choco install $packageName -y
    }
    catch {
        Write-Host "Failed to install $packageName using Chocolatey: $_" -ForegroundColor Red
    }
}

# Function to install software using WinGet
function Install-WingetPackage {
    param (
        [string]$packageName
    )
    Write-Host "Installing $packageName using WinGet..."
    try {
        winget install --id $packageName -e --silent
    }
    catch {
        Write-Host "Failed to install $packageName using WinGet: $_" -ForegroundColor Red
    }
}

# Function to install Internet Download Manager silently
function Install-IDM {
    $idmUrl = "https://download.internetdownloadmanager.com/idman641build2.exe"
    $idmInstaller = "$env:TEMP\idm_installer.exe"
    
    Write-Host "Downloading Internet Download Manager..."
    if (Get-FileFromUrl -url $idmUrl -outputPath $idmInstaller) {
        Write-Host "Installing Internet Download Manager silently..."
        Start-Process -FilePath $idmInstaller -ArgumentList "/silent" -Wait
        Remove-Item $idmInstaller -Force
    }
}

function Install-SoftwareFromUrl {
    param (
        [string]$url,
        [string]$filename,
        [string]$arguments = $null
    )
    $installerPath = "$env:TEMP\$filename"

    Write-Host "Downloading from $url..."
    if (Get-FileFromUrl -url $url -outputPath $installerPath) {
        if ([string]::IsNullOrEmpty($arguments)) {
            Write-Host "Executing installer and waiting for completion..."
            Start-Process -FilePath $installerPath -Wait
        } else {
            Write-Host "Executing installer with arguments and waiting for completion..."
            Start-Process -FilePath $installerPath -ArgumentList $arguments -Wait
        }
        Remove-Item $installerPath -Force
    }
}

function Install-Software {
    param (
        [string]$location,
        [string]$arguments = $null
    )
    $installerPath = $location

    if (Test-Path $installerPath) {
        try {
            if ([string]::IsNullOrEmpty($arguments)) {
                Write-Host "Executing installer from ${location} and waiting for completion..."
                Start-Process -FilePath $installerPath -Wait
            } else {
                Write-Host "Executing installer from ${location} with arguments and waiting for completion..."
                Start-Process -FilePath $installerPath -ArgumentList $arguments -Wait
            }
            Remove-Item $installerPath -Force
        }
        catch {
            Write-Host "Installation failed from ${location}: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Installer not found at ${location}: skipping..." -ForegroundColor Yellow
    }
}

# Install browsers
Install-WingetPackage "Google.Chrome"
Install-WingetPackage "Mozilla.Firefox"

# Install compression tools
Install-WingetPackage "7zip.7zip"
Install-WingetPackage "RARLab.WinRAR"

# Install development tools
Install-WingetPackage "Microsoft.VisualStudioCode"
# Install-WingetPackage "Notepad++.Notepad++"
# Install-WingetPackage "Telegram.TelegramDesktop"
# Install-WingetPackage "Microsoft.VisualStudio.2022.Community"
Install-WingetPackage "ApacheFriends.Xampp"
# Install-WingetPackage "laragon.laragon"
# Install-WingetPackage "qBittorrent.qBittorrent"
Install-WingetPackage "Python.Python.3.12"
Install-WingetPackage "OpenJS.NodeJS"

# Tools specifically installed via Chocolatey
# Install-ChocoPackage "ffmpeg"
Install-ChocoPackage "git"

# Install Internet Download Manager and some others
Install-IDM
Install-SoftwareFromUrl -url "https://get.enterprisedb.com/postgresql/postgresql-17.0-1-windows-x64.exe" -filename "postgresql-17.0-1-windows-x64.exe" -arguments ""

Get-GithubReleaseAsset -repository "abbodi1406/vcredist" -tag "latest" -assetName "VisualCppRedist_AIO_x86_x64.exe" -outputPath "$env:TEMP\VisualCppRedist_AIO_x86_x64.exe"
Install-Software -location "$env:TEMP\VisualCppRedist_AIO_x86_x64.exe" -arguments "/ai /gm2"

# Clean up system after installations
Clear-SystemCache

Write-Host "Installation and cleanup complete!"

# Optional: Create a log file
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

$logContent | Out-File "$env:USERPROFILE\Desktop\software_installation_log_$(Get-Date -Format "yyyyMMdd_HHmmss").txt"
Write-Host "Log file created on desktop: software_installation_log_$(Get-Date -Format "yyyyMMdd_HHmmss").txt"
