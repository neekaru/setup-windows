# make test to list all program

Import-Module ./utils/program_utils.psm1 -Force
Import-Module ./utils/network.psm1 -Force

# $programsToCheck = @("git", "node", "python", "nonexistentprogram")
# $installedPrograms = List-ProgramsInstalled -ProgramNames $programsToCheck
# foreach ($program in $installedPrograms.GetEnumerator()) {
#     if ($program.Value) {
#         Write-Output "$($program.Key) is installed."
#     } else {
#         Write-Output "$($program.Key) is NOT installed."
#     }
# }

# $allInstalledPrograms = Get-AllInstalledPrograms
# Write-Output "Installed Programs:"
# foreach ($program in $allInstalledPrograms) {
#     Write-Output $program
# }

# ============================================
# Set-Hosts Function Examples
# ============================================
# NOTE: These commands require Administrator privileges!

# Example 1: Add a single host entry
# Set-Hosts -Action Add -IPAddress "127.0.0.1" -Hostname "test.local"

# Example 2: Add BebasID preset from URL
# Set-Hosts -Action Add -PresetUrl "https://raw.githubusercontent.com/bebasid/bebasid/master/releases/hosts"

# Example 3: Add from a local preset file
# Set-Hosts -Action Add -PresetFile "C:\path\to\custom-hosts.txt"

# Example 4: Remove a specific hostname
# Set-Hosts -Action Remove -Hostname "test.local"

# Example 5: Remove BebasID preset entries
# Set-Hosts -Action Remove -PresetUrl "https://raw.githubusercontent.com/bebasid/bebasid/master/releases/hosts"

# Example 6: Add without creating backup
# Set-Hosts -Action Add -IPAddress "192.168.1.100" -Hostname "myserver.local" -Backup:$false

# ============================================
# Aria2 Download Test
# ============================================
Write-Host "`nTesting aria2c download integration..." -ForegroundColor Cyan
Import-Module ./utils/download_utils.psm1 -Force

# Check if aria2c is available
$aria2Path = Get-Aria2Path
if ($aria2Path) {
    Write-Host "aria2c found at: $aria2Path" -ForegroundColor Green
} else {
    Write-Host "aria2c not found. Please create bin folder with aria2c.exe or run gui_setup.ps1 to generate package." -ForegroundColor Yellow
}

# Test download with aria2c (non-GitHub URL)
Write-Host "`nTesting download from non-GitHub URL (should use aria2c if available)..." -ForegroundColor Cyan
$testUrl = "https://download.microsoft.com/download/1/7/1/1718ccc4-6315-4d8e-9543-8e28a4e18c4c/dxwebsetup.exe"
$testOutput = Join-Path $env:TEMP "test_dxwebsetup.exe"
Invoke-DownloadFile -Url $testUrl -OutputPath $testOutput -Verbose

if (Test-Path $testOutput) {
    $fileInfo = Get-Item $testOutput
    Write-Host "Download successful! File size: $($fileInfo.Length) bytes" -ForegroundColor Green
    Remove-Item $testOutput -Force
} else {
    Write-Host "Download failed!" -ForegroundColor Red
}

# Test GitHub URL (should use PowerShell method)
Write-Host "`nTesting download from GitHub URL (should use PowerShell method)..." -ForegroundColor Cyan
$githubUrl = "https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip"
Write-Host "URL is GitHub: $(Test-IsGitHubUrl -Url $githubUrl)" -ForegroundColor Cyan
