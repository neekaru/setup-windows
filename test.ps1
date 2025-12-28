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
Write-Host "`nTesting Download-Aria2..." -ForegroundColor Cyan
Import-Module ./utils/soft.psm1 -Force
Download-Aria2

