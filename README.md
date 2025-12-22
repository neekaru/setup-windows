# Setup Windows - Automated Windows Setup Toolkit

Comprehensive PowerShell toolkit for automating Windows setup, software installation, and system configuration.

## 🚀 Features

- **GUI Setup Generator** - Visual interface for generating setup scripts
- **Network Management** - Firewall rules and hosts file configuration
- **File Operations** - Copy, move, delete, and extract files safely
- **Download Utilities** - Advanced file downloading with retry and authentication
- **Program Management** - Check installed programs and install via multiple package managers
- **Modular Design** - Reusable utility modules for custom scripts

## 📁 Project Structure

```
setup-windows/
├── examples/           # Comprehensive examples for all modules
│   ├── README.md      # Complete documentation and quick reference
│   ├── network-examples.ps1
│   ├── download-examples.ps1
│   ├── file-examples.ps1
│   ├── program-utils-examples.ps1
│   └── programs-examples.ps1
├── utils/             # Utility modules
│   ├── network.psm1           # Firewall & hosts management
│   ├── download_utils.psm1    # File downloading
│   ├── file.psm1              # File operations
│   ├── program_utils.psm1     # Program checking
│   └── programs.psm1          # Software installation
├── gui_tools/         # GUI setup generator
│   ├── gui_setup.ps1
│   └── gui_setup.xaml
├── setup_template.ps1 # Setup script template
└── setup.ps1         # Generated setup script
```

## 🎯 Quick Start

### Option 1: Use GUI Setup Generator

```powershell
# Run the GUI to generate setup.ps1
.\gui_tools\gui_setup.ps1
```

### Option 2: Use Utility Modules Directly

```powershell
# Navigate to examples folder
cd examples

# View examples
.\network-examples.ps1
.\programs-examples.ps1

# See examples/README.md for complete guide
```

## 📚 Utility Modules

### Network Module (`utils/network.psm1`)
Manage Windows Firewall rules and hosts file entries.

```powershell
Import-Module .\utils\network.psm1 -Force

# Block application internet access
Set-FirewallRule -Path "C:\App\app.exe" -Action Block -Direction All

# Add local development domain
Set-Hosts -Action Add -IPAddress "127.0.0.1" -Hostname "myapp.local"

# Apply BebasID preset
Set-Hosts -Action Add -PresetUrl "https://raw.githubusercontent.com/bebasid/bebasid/master/releases/hosts"
```

### Download Utilities (`utils/download_utils.psm1`)
Advanced file downloading with headers, cookies, and retry mechanism.

```powershell
Import-Module .\utils\download_utils.psm1 -Force

# Download with retry
Invoke-DownloadWithRetry -Url "https://example.com/file.zip" -OutputPath ".\file.zip" -MaxRetries 3

# Download with authentication
$headers = @{ "Authorization" = "Bearer TOKEN" }
Invoke-DownloadFile -Url "https://api.example.com/file" -OutputPath ".\file.zip" -Headers $headers
```

### File Utilities (`utils/file.psm1`)
Safe file operations including copy, move, delete, and extraction.

```powershell
Import-Module .\utils\file.psm1 -Force

# Backup directory
Copy-FileHandler -SourcePath "C:\Projects" -DestinationPath "D:\Backups" -Recurse

# Extract ZIP
Expand-ZipFile -ZipPath ".\archive.zip" -ExtractPath ".\extracted"

# Safe delete to recycle bin
Remove-FileToRecycleBin -Path "C:\Temp\oldfile.txt"
```

### Program Utilities (`utils/program_utils.psm1`)
Check installed programs and verify system requirements.

```powershell
Import-Module .\utils\program_utils.psm1 -Force

# Check if Git is installed
Test-ProgramInstalled -ProgramName "git"

# Check multiple tools
Get-ProgramInstallationStatus -ProgramNames @("git", "node", "python")

# List all installed programs
Get-InstalledProgram
```

### Programs Module (`utils/programs.psm1`)
Install software via Chocolatey, Winget, Scoop, or direct download.

```powershell
Import-Module .\utils\programs.psm1 -Force

# Install with Chocolatey
Install-WithChocolatey -PackageName "git"

# Install with Winget
Install-WithWinget -PackageName "Git.Git" -Silent

# Install from URL
Install-SoftwareFromUrl -Url "https://example.com/setup.exe" -OutputPath ".\setup.exe" -Silent
```

## 💡 Common Use Cases

### Setup Development Environment
```powershell
# Check and install development tools
Import-Module .\utils\program_utils.psm1 -Force
Import-Module .\utils\programs.psm1 -Force

$tools = @("git", "node", "python", "code")
$status = Get-ProgramInstallationStatus -ProgramNames $tools

foreach ($tool in $status.GetEnumerator()) {
    if (-not $tool.Value) {
        Install-WithChocolatey -PackageName $tool.Key
    }
}
```

### Block Distracting Websites
```powershell
Import-Module .\utils\network.psm1 -Force

$sites = @("facebook.com", "twitter.com", "youtube.com")
foreach ($site in $sites) {
    Set-Hosts -Action Add -IPAddress "0.0.0.0" -Hostname $site
    Set-Hosts -Action Add -IPAddress "0.0.0.0" -Hostname "www.$site"
}
```

### Automated Backup
```powershell
Import-Module .\utils\file.psm1 -Force

$date = Get-Date -Format "yyyyMMdd"
Copy-FileHandler -SourcePath "C:\Projects" -DestinationPath "D:\Backups\Projects_$date" -Recurse
```

## 📖 Documentation

- **Complete Guide**: See [examples/README.md](examples/README.md)
- **Example Scripts**: Browse `examples/` folder
- **Function Help**: Use `Get-Help FunctionName -Full`

## ⚙️ GUI Setup Generator

The GUI tool helps you generate custom `setup.ps1` scripts without manual editing.

### Files
- `setup_template.ps1` - Template with placeholders
- `gui_tools/gui_setup.ps1` - GUI application
- `gui_tools/gui_setup.xaml` - GUI layout
- `package_list.json` - Default package list
- `url_list.json` - Default installer URLs
- `setup.ps1` - Generated output

### Usage
1. Run `.\gui_tools\gui_setup.ps1`
2. Configure settings and select packages
3. Click **Generate setup.ps1**

## 🛠️ Requirements

- Windows 7 or later
- PowerShell 5.1 or later
- Administrator privileges (for most operations)

## ⚠️ Important Notes

- **Run as Administrator** for firewall, hosts, and installation operations
- **Enable script execution**: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
- **Automatic backups** are created for hosts file modifications
- **Safe deletion** uses recycle bin by default

## 🔗 Useful Links

- [Chocolatey Packages](https://community.chocolatey.org/packages)
- [Winget Package Search](https://winget.run/)
- [Scoop Buckets](https://scoop.sh/)
- [BebasID Project](https://github.com/bebasid/bebasid)

## 📝 License

This project is open source. Feel free to use and modify as needed.

---

**For detailed examples and complete documentation, see [examples/README.md](examples/README.md)**
