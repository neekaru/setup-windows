# Requires administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as Administrator!"
    break
}

# Import utility modules
Import-Module ./utils/download.psm1 -Force
Import-Module ./utils/programs.psm1 -Force
Import-Module ./utils/file.psm1 -Force

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

# Install Chocolatey
Write-Output "Installing Chocolatey..."
if (!(Test-Path "$env:ProgramData\chocolatey\choco.exe")) {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    $chocoScript = Join-Path $env:TEMP "install_chocolatey.ps1"
    (New-Object System.Net.WebClient).DownloadFile('https://chocolatey.org/install.ps1', $chocoScript)
    & $chocoScript
    Remove-Item $chocoScript -Force -ErrorAction SilentlyContinue
}

# Install WinGet if not present
Write-Output "Checking WinGet installation..."
if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Output "WinGet not found. Downloading Microsoft.VCLibs.140.00 and Microsoft.UI.Xaml.2.7 UWP packages..."
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

    Write-Output "Installing WinGet..."
    Get-GithubReleaseAsset -repository "microsoft/winget-cli" -assetName "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -outputPath "$env:TEMP\Microsoft.DesktopAppInstaller.msixbundle"
    Add-AppxPackage -Path "$env:TEMP\Microsoft.DesktopAppInstaller.msixbundle"
}

# Install browsers
Install-WithWinget -PackageName "Google.Chrome"
Install-WithWinget -PackageName "Mozilla.Firefox"

# Install compression tools
Install-WithWinget -PackageName "7zip.7zip"
Install-WithWinget -PackageName "RARLab.WinRAR"

# Install development tools
Install-WithWinget -PackageName "Microsoft.VisualStudioCode"
Install-WithWinget -PackageName "ApacheFriends.Xampp.8.2"
Install-WithWinget -PackageName "Laragon" -Version "6.0.0"
Install-WithWinget -PackageName "Python.Python.3.12"
Install-WithWinget -PackageName "OpenJS.NodeJS"

# Tools specifically installed via Chocolatey
Install-WithChocolatey -PackageName "git"

# Install Internet Download Manager and some others
$idmUrl = "https://download.internetdownloadmanager.com/idman641build2.exe"
$idmInstaller = "$env:TEMP\idm_installer.exe"
Install-SoftwareFromUrl -Url $idmUrl -OutputPath $idmInstaller -InstallArguments @("/silent") -RemoveInstaller

# Install PostgreSQL
Install-SoftwareFromUrl -Url "https://get.enterprisedb.com/postgresql/postgresql-17.3-1-windows-x64.exe" -OutputPath "$env:TEMP\postgresql-17.3-1-windows-x64.exe"

# Install Visual C++ Redistributables
$vcRedistUrl = "https://github.com/abbodi1406/vcredist/releases/latest/download/VisualCppRedist_AIO_x86_x64.exe"
Invoke-DownloadFile -Url $vcRedistUrl -OutputPath "$env:TEMP\VisualCppRedist_AIO_x86_x64.exe"
Install-SoftwareManually -InstallerPath "$env:TEMP\VisualCppRedist_AIO_x86_x64.exe" -Arguments @("/ai", "/gm2") -Wait

# Clean up system after installations
Clear-SystemCache

Write-Output "Installation and cleanup complete!"

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
Write-Output "Log file created on desktop: software_installation_log_$(Get-Date -Format "yyyyMMdd_HHmmss").txt"

