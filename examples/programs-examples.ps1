<#
.SYNOPSIS
    Examples for using programs.psm1 module functions.

.DESCRIPTION
    This file contains practical examples for installing software using multiple
    package managers (Chocolatey, Winget, Scoop) and direct installation methods.
#>

# Import the programs module
Import-Module ..\utils\programs.psm1 -Force

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Programs Module Examples" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================
# CHECK PACKAGE MANAGERS EXAMPLES
# ============================================

Write-Host "--- Check Package Managers ---" -ForegroundColor Yellow
Write-Host ""

# Example 1: Check if Chocolatey is available
Write-Host "Example 1: Check if Chocolatey is installed" -ForegroundColor Green
Write-Host 'if (Test-PackageManager -Manager "Chocolatey") {'
Write-Host '    Write-Host "Chocolatey is available!" -ForegroundColor Green'
Write-Host '} else {'
Write-Host '    Write-Host "Chocolatey is NOT available!" -ForegroundColor Red'
Write-Host '}'
# if (Test-PackageManager -Manager "Chocolatey") {
#     Write-Host "Chocolatey is available!" -ForegroundColor Green
# } else {
#     Write-Host "Chocolatey is NOT available!" -ForegroundColor Red
# }

Write-Host ""

# Example 2: Get all available package managers
Write-Host "Example 2: List all available package managers" -ForegroundColor Green
Write-Host '$managers = Get-AvailablePackageManager'
Write-Host 'Write-Host "Available package managers: $($managers -join '', '')"'
# $managers = Get-AvailablePackageManager
# Write-Host "Available package managers: $($managers -join ', ')"

Write-Host ""

# Example 3: Get system installation info
Write-Host "Example 3: Get complete installation info" -ForegroundColor Green
Write-Host '$info = Get-SoftwareInstallationInfo'
Write-Host '$info | ConvertTo-Json -Depth 3'
# $info = Get-SoftwareInstallationInfo
# $info | ConvertTo-Json -Depth 3

Write-Host ""

# ============================================
# CHOCOLATEY INSTALLATION EXAMPLES
# ============================================

Write-Host "--- Chocolatey Installation Examples ---" -ForegroundColor Yellow
Write-Host ""

# Example 4: Install with Chocolatey
Write-Host "Example 4: Install Git using Chocolatey" -ForegroundColor Green
Write-Host 'Install-WithChocolatey -PackageName "git"'
# Install-WithChocolatey -PackageName "git"

Write-Host ""

# Example 5: Install specific version
Write-Host "Example 5: Install specific version with Chocolatey" -ForegroundColor Green
Write-Host 'Install-WithChocolatey -PackageName "nodejs" -Version "18.0.0"'
# Install-WithChocolatey -PackageName "nodejs" -Version "18.0.0"

Write-Host ""

# Example 6: Install with custom arguments
Write-Host "Example 6: Install with custom arguments" -ForegroundColor Green
Write-Host '$args = @("--install-arguments", "/SILENT")'
Write-Host 'Install-WithChocolatey -PackageName "vscode" -Arguments $args'
# $args = @("--install-arguments", "/SILENT")
# Install-WithChocolatey -PackageName "vscode" -Arguments $args

Write-Host ""

# Example 7: Force reinstall
Write-Host "Example 7: Force reinstall with Chocolatey" -ForegroundColor Green
Write-Host 'Install-WithChocolatey -PackageName "git" -Force'
# Install-WithChocolatey -PackageName "git" -Force

Write-Host ""

# ============================================
# WINGET INSTALLATION EXAMPLES
# ============================================

Write-Host "--- Winget Installation Examples ---" -ForegroundColor Yellow
Write-Host ""

# Example 8: Install with Winget
Write-Host "Example 8: Install Python using Winget" -ForegroundColor Green
Write-Host 'Install-WithWinget -PackageName "Python.Python.3.11"'
# Install-WithWinget -PackageName "Python.Python.3.11"

Write-Host ""

# Example 9: Install with silent mode
Write-Host "Example 9: Install silently with Winget" -ForegroundColor Green
Write-Host 'Install-WithWinget -PackageName "Microsoft.VisualStudioCode" -Silent'
# Install-WithWinget -PackageName "Microsoft.VisualStudioCode" -Silent

Write-Host ""

# Example 10: Install specific version with Winget
Write-Host "Example 10: Install specific version with Winget" -ForegroundColor Green
Write-Host 'Install-WithWinget -PackageName "Git.Git" -Version "2.40.0"'
# Install-WithWinget -PackageName "Git.Git" -Version "2.40.0"

Write-Host ""

# ============================================
# SCOOP INSTALLATION EXAMPLES
# ============================================

Write-Host "--- Scoop Installation Examples ---" -ForegroundColor Yellow
Write-Host ""

# Example 11: Install with Scoop
Write-Host "Example 11: Install with Scoop" -ForegroundColor Green
Write-Host 'Install-WithScoop -PackageName "git"'
# Install-WithScoop -PackageName "git"

Write-Host ""

# Example 12: Install from specific bucket
Write-Host "Example 12: Install from specific Scoop bucket" -ForegroundColor Green
Write-Host 'Install-WithScoop -PackageName "vscode" -Bucket "extras"'
# Install-WithScoop -PackageName "vscode" -Bucket "extras"

Write-Host ""

# Example 13: Install globally with Scoop
Write-Host "Example 13: Install globally with Scoop" -ForegroundColor Green
Write-Host 'Install-WithScoop -PackageName "nodejs" -Global'
# Install-WithScoop -PackageName "nodejs" -Global

Write-Host ""

# ============================================
# DIRECT INSTALLATION EXAMPLES
# ============================================

Write-Host "--- Direct Installation Examples ---" -ForegroundColor Yellow
Write-Host ""

# Example 14: Install from URL
Write-Host "Example 14: Download and install from URL" -ForegroundColor Green
Write-Host '$url = "https://example.com/software-installer.exe"'
Write-Host '$output = "C:\Temp\installer.exe"'
Write-Host 'Install-SoftwareFromUrl -Url $url -OutputPath $output -Silent'
# $url = "https://example.com/software-installer.exe"
# $output = "C:\Temp\installer.exe"
# Install-SoftwareFromUrl -Url $url -OutputPath $output -Silent

Write-Host ""

# Example 15: Install from URL with cleanup
Write-Host "Example 15: Install from URL and remove installer" -ForegroundColor Green
Write-Host '$url = "https://example.com/app.exe"'
Write-Host 'Install-SoftwareFromUrl -Url $url -OutputPath ".\installer.exe" -RemoveInstaller -Silent'
# $url = "https://example.com/app.exe"
# Install-SoftwareFromUrl -Url $url -OutputPath ".\installer.exe" -RemoveInstaller -Silent

Write-Host ""

# Example 16: Install from URL with custom arguments
Write-Host "Example 16: Install from URL with custom arguments" -ForegroundColor Green
Write-Host '$url = "https://example.com/setup.exe"'
Write-Host '$args = @("/S", "/D=C:\Program Files\MyApp")'
Write-Host 'Install-SoftwareFromUrl -Url $url -OutputPath ".\setup.exe" -InstallArguments $args'
# $url = "https://example.com/setup.exe"
# $args = @("/S", "/D=C:\Program Files\MyApp")
# Install-SoftwareFromUrl -Url $url -OutputPath ".\setup.exe" -InstallArguments $args

Write-Host ""

# ============================================
# MANUAL INSTALLATION EXAMPLES
# ============================================

Write-Host "--- Manual Installation Examples ---" -ForegroundColor Yellow
Write-Host ""

# Example 17: Run installer manually
Write-Host "Example 17: Run installer with wait" -ForegroundColor Green
Write-Host 'Install-SoftwareManually -InstallerPath "C:\Downloads\setup.exe" -Wait'
# Install-SoftwareManually -InstallerPath "C:\Downloads\setup.exe" -Wait

Write-Host ""

# Example 18: Run installer silently
Write-Host "Example 18: Run installer silently" -ForegroundColor Green
Write-Host 'Install-SoftwareManually -InstallerPath "C:\Downloads\app.exe" -Silent -Wait'
# Install-SoftwareManually -InstallerPath "C:\Downloads\app.exe" -Silent -Wait

Write-Host ""

# Example 19: Run installer with custom arguments
Write-Host "Example 19: Run installer with custom arguments" -ForegroundColor Green
Write-Host '$args = @("/VERYSILENT", "/NORESTART", "/DIR=C:\MyApp")'
Write-Host 'Install-SoftwareManually -InstallerPath "C:\Downloads\setup.exe" -Arguments $args -Wait'
# $args = @("/VERYSILENT", "/NORESTART", "/DIR=C:\MyApp")
# Install-SoftwareManually -InstallerPath "C:\Downloads\setup.exe" -Arguments $args -Wait

Write-Host ""

# ============================================
# PRACTICAL SCENARIOS
# ============================================

Write-Host "--- Practical Scenarios ---" -ForegroundColor Yellow
Write-Host ""

# Scenario 1: Install development environment
Write-Host "Scenario 1: Install Complete Development Environment" -ForegroundColor Magenta
Write-Host "# Install multiple development tools"
Write-Host '$tools = @("git", "nodejs", "python", "vscode")'
Write-Host ''
Write-Host 'foreach ($tool in $tools) {'
Write-Host '    Write-Host "Installing $tool..." -ForegroundColor Cyan'
Write-Host '    Install-WithChocolatey -PackageName $tool'
Write-Host '}'

Write-Host ""

# Scenario 2: Try multiple package managers
Write-Host "Scenario 2: Install with Fallback Package Managers" -ForegroundColor Magenta
Write-Host "# Try Chocolatey first, then Winget, then Scoop"
Write-Host '$packageName = "git"'
Write-Host '$installed = $false'
Write-Host ''
Write-Host 'if (Test-PackageManager -Manager "Chocolatey") {'
Write-Host '    Write-Host "Trying Chocolatey..." -ForegroundColor Cyan'
Write-Host '    $installed = Install-WithChocolatey -PackageName $packageName'
Write-Host '}'
Write-Host ''
Write-Host 'if (-not $installed -and (Test-PackageManager -Manager "Winget")) {'
Write-Host '    Write-Host "Trying Winget..." -ForegroundColor Cyan'
Write-Host '    $installed = Install-WithWinget -PackageName $packageName'
Write-Host '}'
Write-Host ''
Write-Host 'if (-not $installed -and (Test-PackageManager -Manager "Scoop")) {'
Write-Host '    Write-Host "Trying Scoop..." -ForegroundColor Cyan'
Write-Host '    $installed = Install-WithScoop -PackageName $packageName'
Write-Host '}'
Write-Host ''
Write-Host 'if ($installed) {'
Write-Host '    Write-Host "$packageName installed successfully!" -ForegroundColor Green'
Write-Host '} else {'
Write-Host '    Write-Host "Failed to install $packageName" -ForegroundColor Red'
Write-Host '}'

Write-Host ""

# Scenario 3: Batch install from list
Write-Host "Scenario 3: Batch Install from List" -ForegroundColor Magenta
Write-Host "# Install multiple packages from a list"
Write-Host '$packages = @('
Write-Host '    @{ Name = "git"; Manager = "Chocolatey" }'
Write-Host '    @{ Name = "nodejs"; Manager = "Chocolatey" }'
Write-Host '    @{ Name = "python"; Manager = "Winget"; PackageId = "Python.Python.3.11" }'
Write-Host '    @{ Name = "vscode"; Manager = "Scoop"; Bucket = "extras" }'
Write-Host ')'
Write-Host ''
Write-Host 'foreach ($pkg in $packages) {'
Write-Host '    Write-Host "`nInstalling $($pkg.Name) via $($pkg.Manager)..." -ForegroundColor Cyan'
Write-Host '    '
Write-Host '    switch ($pkg.Manager) {'
Write-Host '        "Chocolatey" { Install-WithChocolatey -PackageName $pkg.Name }'
Write-Host '        "Winget" { Install-WithWinget -PackageName $pkg.PackageId }'
Write-Host '        "Scoop" { Install-WithScoop -PackageName $pkg.Name -Bucket $pkg.Bucket }'
Write-Host '    }'
Write-Host '}'

Write-Host ""

# Scenario 4: Install from GitHub release
Write-Host "Scenario 4: Install from GitHub Release" -ForegroundColor Magenta
Write-Host "# Download and install latest release from GitHub"
Write-Host '$url = "https://github.com/user/repo/releases/download/v1.0.0/installer.exe"'
Write-Host '$output = "$env:TEMP\installer.exe"'
Write-Host ''
Write-Host 'Write-Host "Downloading from GitHub..." -ForegroundColor Cyan'
Write-Host 'Install-SoftwareFromUrl -Url $url -OutputPath $output -RemoveInstaller -Silent'

Write-Host ""

# Scenario 5: Check and install if missing
Write-Host "Scenario 5: Check and Install if Missing" -ForegroundColor Magenta
Write-Host "# Check if software is installed, install if missing"
Write-Host 'Import-Module ..\utils\program_utils.psm1 -Force'
Write-Host ''
Write-Host '$software = "git"'
Write-Host 'if (-not (Test-ProgramInstalled -ProgramName $software)) {'
Write-Host '    Write-Host "$software not found. Installing..." -ForegroundColor Yellow'
Write-Host '    Install-WithChocolatey -PackageName $software'
Write-Host '} else {'
Write-Host '    Write-Host "$software is already installed!" -ForegroundColor Green'
Write-Host '}'

Write-Host ""

# Scenario 6: Install with best available manager
Write-Host "Scenario 6: Auto-Select Best Package Manager" -ForegroundColor Magenta
Write-Host "# Automatically use the best available package manager"
Write-Host '$packageName = "nodejs"'
Write-Host '$managers = Get-AvailablePackageManager'
Write-Host ''
Write-Host 'if ($managers.Count -eq 0) {'
Write-Host '    Write-Host "No package managers available!" -ForegroundColor Red'
Write-Host '} else {'
Write-Host '    $preferredOrder = @("Chocolatey", "Winget", "Scoop")'
Write-Host '    $selectedManager = $preferredOrder | Where-Object { $managers -contains $_ } | Select-Object -First 1'
Write-Host '    '
Write-Host '    Write-Host "Using $selectedManager to install $packageName" -ForegroundColor Cyan'
Write-Host '    '
Write-Host '    switch ($selectedManager) {'
Write-Host '        "Chocolatey" { Install-WithChocolatey -PackageName $packageName }'
Write-Host '        "Winget" { Install-WithWinget -PackageName $packageName }'
Write-Host '        "Scoop" { Install-WithScoop -PackageName $packageName }'
Write-Host '    }'
Write-Host '}'

Write-Host ""
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "End of Examples" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "NOTE: Uncomment the lines you want to execute!" -ForegroundColor Yellow
Write-Host "TIP: Run PowerShell as Administrator for installations!" -ForegroundColor Red
Write-Host "INFO: Check available package managers first!" -ForegroundColor Cyan
