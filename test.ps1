# make test to list all program


Import-Module ./utils/program_utils.psm1 -Force

# $programsToCheck = @("git", "node", "python", "nonexistentprogram")
# $installedPrograms = List-ProgramsInstalled -ProgramNames $programsToCheck
# foreach ($program in $installedPrograms.GetEnumerator()) {
#     if ($program.Value) {
#         Write-Output "$($program.Key) is installed."
#     } else {
#         Write-Output "$($program.Key) is NOT installed."
#     }
# }

$allInstalledPrograms = Get-AllInstalledPrograms
Write-Output "Installed Programs:"
foreach ($program in $allInstalledPrograms) {
    Write-Output $program
}
