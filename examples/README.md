# Setup Windows - Examples & Documentation

Complete examples and reference guide for all utility modules.

## 📁 Example Files

| File | Module | Description |
|------|--------|-------------|
| `network-examples.ps1` | `network.psm1` | Firewall rules and hosts file management |
| `download-examples.ps1` | `download_utils.psm1` | File downloading with headers, cookies, retry |
| `file-examples.ps1` | `file.psm1` | File operations (copy, move, delete, extract) |
| `program-utils-examples.ps1` | `program_utils.psm1` | Check installed programs |
| `programs-examples.ps1` | `programs.psm1` | Install software via package managers |

## 🚀 Quick Start

```powershell
# 1. Run PowerShell as Administrator
# 2. Navigate to examples folder
cd d:\Project\malas\1\setup-windows\examples

# 3. View examples (choose one)
.\network-examples.ps1
.\download-examples.ps1
.\file-examples.ps1
.\program-utils-examples.ps1
.\programs-examples.ps1

# 4. To execute: Open file, uncomment lines, run script
```

## ⚡ Quick Command Reference

### Network Module
```powershell
Import-Module ..\utils\network.psm1 -Force

# Firewall
Set-FirewallRule -Path "C:\App\app.exe" -Action Block -Direction All
Delete-FirewallRule -Path "C:\App\app.exe" -Action Block -Direction All

# Hosts
Set-Hosts -Action Add -IPAddress "127.0.0.1" -Hostname "myapp.local"
Set-Hosts -Action Add -PresetUrl "https://raw.githubusercontent.com/bebasid/bebasid/master/releases/hosts"
Set-Hosts -Action Remove -Hostname "myapp.local"
```

### Download Utilities
```powershell
Import-Module ..\utils\download_utils.psm1 -Force

Invoke-DownloadFile -Url "URL" -OutputPath ".\file.zip"
Invoke-DownloadWithRetry -Url "URL" -OutputPath ".\file.zip" -MaxRetries 3

$headers = @{ "Authorization" = "Bearer TOKEN" }
Invoke-DownloadFile -Url "URL" -OutputPath ".\file.zip" -Headers $headers
```

### File Utilities
```powershell
Import-Module ..\utils\file.psm1 -Force

Copy-FileHandler -SourcePath "C:\Source" -DestinationPath "C:\Dest" -Recurse
Move-FileHandler -SourcePath "C:\Source\file.txt" -DestinationPath "C:\Dest\file.txt"
Remove-FileToRecycleBin -Path "C:\file.txt"
Expand-ZipFile -ZipPath ".\archive.zip" -ExtractPath ".\extracted"
```

### Program Utilities
```powershell
Import-Module ..\utils\program_utils.psm1 -Force

Test-ProgramInstalled -ProgramName "git"
Get-ProgramInstallationStatus -ProgramNames @("git", "node", "python")
Get-InstalledProgram
```

### Programs Module
```powershell
Import-Module ..\utils\programs.psm1 -Force

Get-AvailablePackageManager
Install-WithChocolatey -PackageName "git"
Install-WithWinget -PackageName "Git.Git" -Silent
Install-WithScoop -PackageName "git"
Install-SoftwareFromUrl -Url "URL" -OutputPath ".\installer.exe" -Silent
```

## 📚 Module Overview

### Network (`network.psm1`)
- `Set-FirewallRule` - Create firewall rules for apps
- `Delete-FirewallRule` - Remove firewall rules
- `Set-Hosts` - Manage hosts file (add/remove entries, presets)

### Download Utilities (`download_utils.psm1`)
- `Invoke-DownloadFile` - Download with headers, cookies
- `Invoke-DownloadWithRetry` - Download with retry mechanism
- `Get-DownloadSpeed` - Get file information
- `Get-HttpHeader` - Fetch HTTP headers

### File Utilities (`file.psm1`)
- `Copy-FileHandler` - Copy files/directories
- `Move-FileHandler` - Move files/directories
- `Remove-FileToRecycleBin` - Safe delete
- `Remove-FileVerbose` - Permanent delete
- `Expand-ZipFile` - Extract ZIP archives

### Program Utilities (`program_utils.psm1`)
- `Test-ProgramInstalled` - Check if program is installed
- `Get-ProgramInstallationStatus` - Check multiple programs
- `Get-InstalledProgram` - List all installed programs

### Programs (`programs.psm1`)
- `Test-PackageManager` - Check package manager availability
- `Install-WithChocolatey` - Install via Chocolatey
- `Install-WithWinget` - Install via Winget
- `Install-WithScoop` - Install via Scoop
- `Install-SoftwareFromUrl` - Download and install from URL

## 🎯 Common Workflows

### Setup Development Environment
```powershell
Import-Module ..\utils\program_utils.psm1 -Force
Import-Module ..\utils\programs.psm1 -Force
Import-Module ..\utils\network.psm1 -Force

# Check what's installed
$tools = @("git", "node", "python", "code")
Get-ProgramInstallationStatus -ProgramNames $tools

# Install missing tools
Install-WithChocolatey -PackageName "git"
Install-WithChocolatey -PackageName "nodejs"
Install-WithChocolatey -PackageName "python"
Install-WithChocolatey -PackageName "vscode"

# Setup local domains
Set-Hosts -Action Add -IPAddress "127.0.0.1" -Hostname "myproject.local"
Set-Hosts -Action Add -IPAddress "127.0.0.1" -Hostname "api.myproject.local"
```

### Download and Install Software
```powershell
Import-Module ..\utils\download_utils.psm1 -Force
Import-Module ..\utils\programs.psm1 -Force

# Download installer
Invoke-DownloadWithRetry -Url "https://example.com/setup.exe" -OutputPath ".\setup.exe" -MaxRetries 3

# Install
Install-SoftwareManually -InstallerPath ".\setup.exe" -Silent -Wait
```

### Backup and Organize Files
```powershell
Import-Module ..\utils\file.psm1 -Force

# Create backup
$date = Get-Date -Format "yyyyMMdd"
Copy-FileHandler -SourcePath "C:\Projects" -DestinationPath "D:\Backups\Projects_$date" -Recurse

# Extract archives
$zips = Get-ChildItem -Path "C:\Downloads" -Filter "*.zip"
foreach ($zip in $zips) {
    Expand-ZipFile -ZipPath $zip.FullName -ExtractPath "C:\Extracted\$($zip.BaseName)"
}

# Clean up old files
$oldFiles = Get-ChildItem -Path "C:\Temp" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) }
foreach ($file in $oldFiles) {
    Remove-FileToRecycleBin -Path $file.FullName -Force
}
```

### Block Application Internet Access
```powershell
Import-Module ..\utils\network.psm1 -Force

# Block single application
Set-FirewallRule -Path "C:\Program Files\App\app.exe" -Action Block -Direction All

# Block all executables in folder
Set-FirewallRule -Path "C:\Program Files\App" -Action Block -Direction All

# Remove rules later
Delete-FirewallRule -Path "C:\Program Files\App" -Action Block -Direction All
```

## 🛠️ Troubleshooting

### Access Denied
```powershell
# Run PowerShell as Administrator
# Right-click PowerShell → "Run as Administrator"
```

### Execution Policy Error
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Module Not Found
```powershell
# Use correct relative path from examples folder
Import-Module ..\utils\network.psm1 -Force
```

### Check if Running as Admin
```powershell
([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
```

### View Hosts File
```powershell
notepad C:\Windows\System32\drivers\etc\hosts
```

### Flush DNS Cache
```powershell
ipconfig /flushdns
```

### Get Function Help
```powershell
Get-Help Set-FirewallRule -Full
Get-Help Invoke-DownloadFile -Detailed
```

## 💡 Tips

- **Use -Verbose**: Add `-Verbose` flag for detailed output
- **Tab Completion**: Type partial command and press Tab
- **Save Results**: `$result = Command` to store output
- **Filter Results**: Use `Where-Object` to filter
- **Export**: `Command | Out-File output.txt`
- **Interactive View**: `Command | Out-GridView`

## 🔗 Useful Links

- [Chocolatey Packages](https://community.chocolatey.org/packages)
- [Winget Package Search](https://winget.run/)
- [Scoop Buckets](https://scoop.sh/)
- [BebasID Project](https://github.com/bebasid/bebasid)

---

**For detailed examples, open the individual `*-examples.ps1` files!**
