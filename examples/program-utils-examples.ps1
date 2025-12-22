<#
.SYNOPSIS
    Examples for using program_utils.psm1 module functions.

.DESCRIPTION
    This file contains practical examples for checking installed programs,
    verifying program installation status, and listing all installed software.
#>

# Import the program utilities module
Import-Module ..\utils\program_utils.psm1 -Force

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Program Utilities Examples" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================
# CHECK SINGLE PROGRAM EXAMPLES
# ============================================

Write-Host "--- Check Single Program Examples ---" -ForegroundColor Yellow
Write-Host ""

# Example 1: Check if Git is installed
Write-Host "Example 1: Check if Git is installed" -ForegroundColor Green
Write-Host 'if (Test-ProgramInstalled -ProgramName "git") {'
Write-Host '    Write-Host "Git is installed!" -ForegroundColor Green'
Write-Host '} else {'
Write-Host '    Write-Host "Git is NOT installed!" -ForegroundColor Red'
Write-Host '}'
# if (Test-ProgramInstalled -ProgramName "git") {
#     Write-Host "Git is installed!" -ForegroundColor Green
# } else {
#     Write-Host "Git is NOT installed!" -ForegroundColor Red
# }

Write-Host ""

# Example 2: Check if Node.js is installed
Write-Host "Example 2: Check if Node.js is installed" -ForegroundColor Green
Write-Host '$isInstalled = Test-ProgramInstalled -ProgramName "node"'
Write-Host 'Write-Host "Node.js installed: $isInstalled"'
# $isInstalled = Test-ProgramInstalled -ProgramName "node"
# Write-Host "Node.js installed: $isInstalled"

Write-Host ""

# Example 3: Check if Python is installed
Write-Host "Example 3: Check if Python is installed" -ForegroundColor Green
Write-Host 'Test-ProgramInstalled -ProgramName "python"'
# Test-ProgramInstalled -ProgramName "python"

Write-Host ""

# ============================================
# CHECK MULTIPLE PROGRAMS EXAMPLES
# ============================================

Write-Host "--- Check Multiple Programs Examples ---" -ForegroundColor Yellow
Write-Host ""

# Example 4: Check multiple programs at once
Write-Host "Example 4: Check multiple development tools" -ForegroundColor Green
Write-Host '$programs = @("git", "node", "python", "code")'
Write-Host '$status = Get-ProgramInstallationStatus -ProgramNames $programs'
Write-Host 'foreach ($program in $status.GetEnumerator()) {'
Write-Host '    $statusText = if ($program.Value) { "✓ Installed" } else { "✗ Not Installed" }'
Write-Host '    $color = if ($program.Value) { "Green" } else { "Red" }'
Write-Host '    Write-Host "$($program.Key): $statusText" -ForegroundColor $color'
Write-Host '}'
# $programs = @("git", "node", "python", "code")
# $status = Get-ProgramInstallationStatus -ProgramNames $programs
# foreach ($program in $status.GetEnumerator()) {
#     $statusText = if ($program.Value) { "✓ Installed" } else { "✗ Not Installed" }
#     $color = if ($program.Value) { "Green" } else { "Red" }
#     Write-Host "$($program.Key): $statusText" -ForegroundColor $color
# }

Write-Host ""

# Example 5: Check required tools for a project
Write-Host "Example 5: Verify project requirements" -ForegroundColor Green
Write-Host '$requiredTools = @("git", "node", "npm", "docker")'
Write-Host '$status = Get-ProgramInstallationStatus -ProgramNames $requiredTools'
Write-Host '$allInstalled = ($status.Values | Where-Object { -not $_ }).Count -eq 0'
Write-Host 'if ($allInstalled) {'
Write-Host '    Write-Host "All required tools are installed!" -ForegroundColor Green'
Write-Host '} else {'
Write-Host '    Write-Host "Missing tools:" -ForegroundColor Red'
Write-Host '    $status.GetEnumerator() | Where-Object { -not $_.Value } | ForEach-Object {'
Write-Host '        Write-Host "  - $($_.Key)" -ForegroundColor Red'
Write-Host '    }'
Write-Host '}'
# $requiredTools = @("git", "node", "npm", "docker")
# $status = Get-ProgramInstallationStatus -ProgramNames $requiredTools
# $allInstalled = ($status.Values | Where-Object { -not $_ }).Count -eq 0
# if ($allInstalled) {
#     Write-Host "All required tools are installed!" -ForegroundColor Green
# } else {
#     Write-Host "Missing tools:" -ForegroundColor Red
#     $status.GetEnumerator() | Where-Object { -not $_.Value } | ForEach-Object {
#         Write-Host "  - $($_.Key)" -ForegroundColor Red
#     }
# }

Write-Host ""

# ============================================
# LIST ALL INSTALLED PROGRAMS EXAMPLES
# ============================================

Write-Host "--- List All Installed Programs Examples ---" -ForegroundColor Yellow
Write-Host ""

# Example 6: Get all installed programs
Write-Host "Example 6: List all installed programs" -ForegroundColor Green
Write-Host '$allPrograms = Get-InstalledProgram'
Write-Host 'Write-Host "Total programs installed: $($allPrograms.Count)"'
Write-Host '$allPrograms | Select-Object -First 10'
# $allPrograms = Get-InstalledProgram
# Write-Host "Total programs installed: $($allPrograms.Count)"
# $allPrograms | Select-Object -First 10

Write-Host ""

# Example 7: Get programs without PATH programs
Write-Host "Example 7: List only registry-installed programs" -ForegroundColor Green
Write-Host '$registryPrograms = Get-InstalledProgram -IncludePathPrograms $false'
Write-Host 'Write-Host "Registry programs: $($registryPrograms.Count)"'
# $registryPrograms = Get-InstalledProgram -IncludePathPrograms $false
# Write-Host "Registry programs: $($registryPrograms.Count)"

Write-Host ""

# Example 8: Get programs with custom exclusions
Write-Host "Example 8: List programs with custom exclusions" -ForegroundColor Green
Write-Host '$excludeList = @("Update*", "Driver*", "Microsoft*")'
Write-Host '$programs = Get-InstalledProgram -ExcludeKeywords $excludeList'
Write-Host 'Write-Host "Filtered programs: $($programs.Count)"'
# $excludeList = @("Update*", "Driver*", "Microsoft*")
# $programs = Get-InstalledProgram -ExcludeKeywords $excludeList
# Write-Host "Filtered programs: $($programs.Count)"

Write-Host ""

# Example 9: Search for specific programs
Write-Host "Example 9: Search for programs containing 'Visual'" -ForegroundColor Green
Write-Host '$allPrograms = Get-InstalledProgram'
Write-Host '$visualPrograms = $allPrograms | Where-Object { $_ -like "*Visual*" }'
Write-Host 'Write-Host "Programs with ''Visual'': $($visualPrograms.Count)"'
Write-Host '$visualPrograms'
# $allPrograms = Get-InstalledProgram
# $visualPrograms = $allPrograms | Where-Object { $_ -like "*Visual*" }
# Write-Host "Programs with 'Visual': $($visualPrograms.Count)"
# $visualPrograms

Write-Host ""

# ============================================
# PRACTICAL SCENARIOS
# ============================================

Write-Host "--- Practical Scenarios ---" -ForegroundColor Yellow
Write-Host ""

# Scenario 1: Development environment check
Write-Host "Scenario 1: Development Environment Check" -ForegroundColor Magenta
Write-Host "# Check if development environment is ready"
Write-Host '$devTools = @{'
Write-Host '    "Git" = "git"'
Write-Host '    "Node.js" = "node"'
Write-Host '    "NPM" = "npm"'
Write-Host '    "Python" = "python"'
Write-Host '    "VS Code" = "code"'
Write-Host '}'
Write-Host ''
Write-Host 'Write-Host "=== Development Environment Check ===" -ForegroundColor Cyan'
Write-Host 'foreach ($tool in $devTools.GetEnumerator()) {'
Write-Host '    $installed = Test-ProgramInstalled -ProgramName $tool.Value'
Write-Host '    $status = if ($installed) { "✓" } else { "✗" }'
Write-Host '    $color = if ($installed) { "Green" } else { "Red" }'
Write-Host '    Write-Host "$status $($tool.Key)" -ForegroundColor $color'
Write-Host '}'

Write-Host ""

# Scenario 2: Generate installed software report
Write-Host "Scenario 2: Generate Installed Software Report" -ForegroundColor Magenta
Write-Host "# Create a report of all installed software"
Write-Host '$programs = Get-InstalledProgram'
Write-Host '$reportPath = "C:\Reports\installed_programs_$(Get-Date -Format ''yyyyMMdd'').txt"'
Write-Host ''
Write-Host '$report = @()'
Write-Host '$report += "Installed Programs Report"'
Write-Host '$report += "Generated: $(Get-Date)"'
Write-Host '$report += "Total Programs: $($programs.Count)"'
Write-Host '$report += ""'
Write-Host '$report += "Programs:"'
Write-Host '$report += $programs | Sort-Object'
Write-Host ''
Write-Host '$report | Out-File -FilePath $reportPath'
Write-Host 'Write-Host "Report saved to: $reportPath"'

Write-Host ""

# Scenario 3: Check before installation
Write-Host "Scenario 3: Check Before Installing Software" -ForegroundColor Magenta
Write-Host "# Check if software is already installed before installing"
Write-Host '$softwareToInstall = "git"'
Write-Host ''
Write-Host 'if (Test-ProgramInstalled -ProgramName $softwareToInstall) {'
Write-Host '    Write-Host "$softwareToInstall is already installed. Skipping installation." -ForegroundColor Yellow'
Write-Host '} else {'
Write-Host '    Write-Host "$softwareToInstall is not installed. Proceeding with installation..." -ForegroundColor Green'
Write-Host '    # Add installation command here'
Write-Host '    # choco install git -y'
Write-Host '}'

Write-Host ""

# Scenario 4: Find programs by pattern
Write-Host "Scenario 4: Find Programs by Pattern" -ForegroundColor Magenta
Write-Host "# Find all Adobe programs"
Write-Host '$allPrograms = Get-InstalledProgram'
Write-Host '$adobePrograms = $allPrograms | Where-Object { $_ -like "*Adobe*" }'
Write-Host ''
Write-Host 'Write-Host "Adobe Programs Found: $($adobePrograms.Count)" -ForegroundColor Cyan'
Write-Host 'foreach ($program in $adobePrograms) {'
Write-Host '    Write-Host "  - $program"'
Write-Host '}'

Write-Host ""

# Scenario 5: Compare installed programs between machines
Write-Host "Scenario 5: Export Program List for Comparison" -ForegroundColor Magenta
Write-Host "# Export program list to compare with another machine"
Write-Host '$programs = Get-InstalledProgram'
Write-Host '$exportPath = "C:\Exports\programs_$env:COMPUTERNAME.json"'
Write-Host ''
Write-Host '$exportData = @{'
Write-Host '    ComputerName = $env:COMPUTERNAME'
Write-Host '    Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"'
Write-Host '    Programs = $programs'
Write-Host '    Count = $programs.Count'
Write-Host '}'
Write-Host ''
Write-Host '$exportData | ConvertTo-Json | Out-File -FilePath $exportPath'
Write-Host 'Write-Host "Program list exported to: $exportPath"'

Write-Host ""

# Scenario 6: Verify software suite installation
Write-Host "Scenario 6: Verify Complete Software Suite" -ForegroundColor Magenta
Write-Host "# Check if entire software suite is installed"
Write-Host '$suite = @{'
Write-Host '    "Web Development" = @("node", "npm", "git", "code")'
Write-Host '    "Python Development" = @("python", "pip")'
Write-Host '    "Database" = @("mysql", "mongodb")'
Write-Host '}'
Write-Host ''
Write-Host 'foreach ($category in $suite.GetEnumerator()) {'
Write-Host '    Write-Host "`n=== $($category.Key) ===" -ForegroundColor Cyan'
Write-Host '    $status = Get-ProgramInstallationStatus -ProgramNames $category.Value'
Write-Host '    foreach ($tool in $status.GetEnumerator()) {'
Write-Host '        $symbol = if ($tool.Value) { "✓" } else { "✗" }'
Write-Host '        $color = if ($tool.Value) { "Green" } else { "Red" }'
Write-Host '        Write-Host "$symbol $($tool.Key)" -ForegroundColor $color'
Write-Host '    }'
Write-Host '}'

Write-Host ""

# Scenario 7: Count programs by vendor
Write-Host "Scenario 7: Count Programs by Vendor" -ForegroundColor Magenta
Write-Host "# Count how many programs from each vendor"
Write-Host '$allPrograms = Get-InstalledProgram'
Write-Host '$vendors = @("Microsoft", "Google", "Adobe", "Mozilla")'
Write-Host ''
Write-Host 'Write-Host "Programs by Vendor:" -ForegroundColor Cyan'
Write-Host 'foreach ($vendor in $vendors) {'
Write-Host '    $count = ($allPrograms | Where-Object { $_ -like "*$vendor*" }).Count'
Write-Host '    Write-Host "$vendor: $count programs"'
Write-Host '}'

Write-Host ""
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "End of Examples" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "NOTE: Uncomment the lines you want to execute!" -ForegroundColor Yellow
Write-Host "TIP: These checks are useful for setup scripts!" -ForegroundColor Cyan
