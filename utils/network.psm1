<#
.SYNOPSIS
    Network utilities module for managing Windows Firewall rules and hosts settings.

.DESCRIPTION
    This module provides functions to create and delete Windows Firewall rules
    for applications (executables). It supports both individual files and folders
    containing multiple executables.
#>

<#
.SYNOPSIS
    Creates Windows Firewall rules for executable files.

.DESCRIPTION
    Creates firewall rules to allow or block traffic for one or more executables.
    Can process a single .exe file or all .exe files in a directory.

.PARAMETER Path
    Path to an executable file or folder containing executables.

.PARAMETER Action
    The action to take: 'Allow' or 'Block' traffic.

.PARAMETER Direction
    Traffic direction: 'Inbound', 'Outbound', or 'All' (both directions).

.EXAMPLE
    Set-FirewallRule -Path "C:\Program Files\MyApp" -Action Block -Direction All
    Blocks all inbound and outbound traffic for all executables in the MyApp folder.

.EXAMPLE
    Set-FirewallRule -Path "C:\Program Files\MyApp\app.exe" -Action Allow -Direction Inbound
    Allows inbound traffic for the specific app.exe file.
#>
function Set-FirewallRule {
    [CmdletBinding(SupportsShouldProcess)]
    Params (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateSet('Allow', 'Block')]
        [string]$Action,

        [Parameter(Mandatory)]
        [ValidateSet('Inbound', 'Outbound', 'All')]
        [string]$Direction
    )

    # Check if the path is a folder or a single file
    $isFolder = Test-Path -Path $Path -PathType Container
    
    # Get list of executables: all .exe files in folder, or the single file
    $listApp = if ($isFolder) {
        Get-ChildItem -Path $Path -Filter *.exe -File
    } else {
        Get-Item -Path $Path
    }

    # Expand 'All' direction into both Inbound and Outbound
    $directions = if ($Direction -eq 'All') { 'Inbound', 'Outbound' } else { $Direction }

    # Create firewall rules for each executable and direction
    foreach ($app in $listApp) {
        if ($app.Extension -eq ".exe") {
            foreach ($dir in $directions) {
                # Generate a descriptive rule name: e.g., "Block Outbound - chrome"
                $ruleName = "$Action $dir - $($app.BaseName)"
                
                # Create the firewall rule
                if ($PSCmdlet.ShouldProcess($ruleName, "Create firewall rule")) {
                    New-NetFirewallRule -DisplayName $ruleName -Direction $dir -Action $Action -Program $app.FullName -Enabled True
                    Write-Information "Created rule: $ruleName" -InformationAction Continue
                }
            }
        }
    }
}

<#
.SYNOPSIS
    Deletes Windows Firewall rules for executable files.

.DESCRIPTION
    Removes firewall rules that were previously created for one or more executables.
    Can process a single .exe file or all .exe files in a directory.
    Includes error handling to gracefully handle non-existent rules.

.PARAMETER Path
    Path to an executable file or folder containing executables.

.PARAMETER Action
    The action type of rules to delete: 'Allow' or 'Block'.

.PARAMETER Direction
    Traffic direction of rules to delete: 'Inbound', 'Outbound', or 'All' (both directions).

.EXAMPLE
    Delete-FirewallRule -Path "C:\Program Files\MyApp" -Action Block -Direction All
    Deletes all block rules (inbound and outbound) for all executables in the MyApp folder.

.EXAMPLE
    Delete-FirewallRule -Path "C:\Program Files\MyApp\app.exe" -Action Allow -Direction Inbound
    Deletes the inbound allow rule for the specific app.exe file.
#>
function Remove-FirewallRule {
    [CmdletBinding(SupportsShouldProcess)]
    Params (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateSet('Allow', 'Block')]
        [string]$Action,

        [Parameter(Mandatory)]
        [ValidateSet('Inbound', 'Outbound', 'All')]
        [string]$Direction
    )

    # Check if the path is a folder or a single file
    $isFolder = Test-Path -Path $Path -PathType Container
    
    # Get list of executables: all .exe files in folder, or the single file
    $listApp = if ($isFolder) {
        Get-ChildItem -Path $Path -Filter *.exe -File
    } else {
        Get-Item -Path $Path
    }

    # Expand 'All' direction into both Inbound and Outbound
    $directions = if ($Direction -eq 'All') { 'Inbound', 'Outbound' } else { $Direction }

    # Delete firewall rules for each executable and direction
    foreach ($app in $listApp) {
        if ($app.Extension -eq ".exe") {
            foreach ($dir in $directions) {
                # Generate the rule name to delete: e.g., "Block Outbound - chrome"
                $ruleName = "$Action $dir - $($app.BaseName)"
                
                # Attempt to remove the firewall rule with error handling
                try {
                    $existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
                    
                    if ($existingRule -and $PSCmdlet.ShouldProcess($ruleName, "Remove firewall rule")) {
                        Remove-NetFirewallRule -DisplayName $ruleName -ErrorAction Stop
                        Write-Information "Deleted rule: $ruleName" -InformationAction Continue
                    } elseif (-not $existingRule) {
                        Write-Verbose "Rule not found (skipping): $ruleName"
                    }
                } catch {
                    Write-Warning "Failed to delete rule '$ruleName': $_"
                }
            }
        }
    }
}

<#
.SYNOPSIS
    Manages Windows hosts file entries.

.DESCRIPTION
    Adds or removes entries from the Windows hosts file (C:\Windows\System32\drivers\etc\hosts).
    Supports individual entries, preset lists from URLs (like BebasID), and automatic backup.
    Requires administrator privileges.

.PARAMETER Action
    The action to perform: 'Add' or 'Remove'.

.PARAMETER IPAddress
    The IP address for the host entry (required when adding individual entries).

.PARAMETER Hostname
    The hostname or domain name (required when adding individual entries).

.PARAMETER PresetUrl
    URL to a hosts file preset (e.g., BebasID or other community lists).
    The function will download and parse the content.

.PARAMETER PresetFile
    Path to a local preset file containing hosts entries.

.PARAMETER Backup
    Create a backup of the hosts file before making changes (default: $true).

.EXAMPLE
    Set-Hosts -Action Add -IPAddress "127.0.0.1" -Hostname "test.local"
    Adds a single entry to the hosts file.

.EXAMPLE
    Set-Hosts -Action Add -PresetUrl "https://raw.githubusercontent.com/bebasid/bebasid/master/releases/hosts"
    Downloads and adds BebasID preset to the hosts file.

.EXAMPLE
    Set-Hosts -Action Remove -Hostname "test.local"
    Removes all entries for test.local from the hosts file.

.EXAMPLE
    Set-Hosts -Action Remove -PresetUrl "https://raw.githubusercontent.com/bebasid/bebasid/master/releases/hosts"
    Removes all entries from the BebasID preset.
#>
function Set-HostEntry {
    [CmdletBinding(DefaultParameterSetName = 'Individual', SupportsShouldProcess)]
    Param (
        [Parameter(Mandatory)]
        [ValidateSet('Add', 'Remove')]
        [string]$Action,

        [Parameter(ParameterSetName = 'Individual')]
        [string]$IPAddress,

        [Parameter(ParameterSetName = 'Individual')]
        [Parameter(ParameterSetName = 'RemoveByHostname')]
        [string]$Hostname,

        [Parameter(ParameterSetName = 'PresetUrl')]
        [string]$PresetUrl,

        [Parameter(ParameterSetName = 'PresetFile')]
        [string]$PresetFile,

        [switch]$Backup
    )

    # Check for administrator privileges
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Error "This function requires administrator privileges. Please run as Administrator."
        return
    }

    # Define hosts file path
    $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"

    # Verify hosts file exists
    if (-not (Test-Path $hostsPath)) {
        Write-Error "Hosts file not found at: $hostsPath"
        return
    }

    # Create backup if requested
    if ($Backup) {
        $backupPath = "$hostsPath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        try {
            Copy-Item -Path $hostsPath -Destination $backupPath -Force
            Write-Information "Backup created: $backupPath" -InformationAction Continue
        } catch {
            Write-Warning "Failed to create backup: $_"
        }
    }

    # Read current hosts file content
    try {
        $hostsContent = Get-Content -Path $hostsPath -ErrorAction Stop
    } catch {
        Write-Error "Failed to read hosts file: $_"
        return
    }

    # Process based on parameter set
    $entriesToProcess = @()

    if ($PSCmdlet.ParameterSetName -eq 'Individual') {
        # Single entry mode
        if ($Action -eq 'Add' -and (-not $IPAddress -or -not $Hostname)) {
            Write-Error "Both IPAddress and Hostname are required when adding individual entries."
            return
        }
        if ($Action -eq 'Add') {
            $entriesToProcess += [PSCustomObject]@{
                IPAddress = $IPAddress
                Hostname = $Hostname
            }
        } elseif ($Action -eq 'Remove' -and $Hostname) {
            # Will be handled in removal logic
            $entriesToProcess += [PSCustomObject]@{
                IPAddress = $null
                Hostname = $Hostname
            }
        }
    } elseif ($PSCmdlet.ParameterSetName -eq 'PresetUrl') {
        # Download preset from URL
        Write-Information "Downloading preset from: $PresetUrl" -InformationAction Continue
        try {
            $presetContent = (Invoke-WebRequest -Uri $PresetUrl -UseBasicParsing).Content -split "`n"
            $entriesToProcess = ConvertFrom-HostsContent -Content $presetContent
            Write-Information "Downloaded $($entriesToProcess.Count) entries from preset" -InformationAction Continue
        } catch {
            Write-Error "Failed to download preset: $_"
            return
        }
    } elseif ($PSCmdlet.ParameterSetName -eq 'PresetFile') {
        # Load preset from local file
        if (-not (Test-Path $PresetFile)) {
            Write-Error "Preset file not found: $PresetFile"
            return
        }
        try {
            $presetContent = Get-Content -Path $PresetFile
            $entriesToProcess = ConvertFrom-HostsContent -Content $presetContent
            Write-Information "Loaded $($entriesToProcess.Count) entries from preset file" -InformationAction Continue
        } catch {
            Write-Error "Failed to read preset file: $_"
            return
        }
    }

    # Perform the action
    if ($Action -eq 'Add') {
        $newContent = Add-HostEntry -CurrentContent $hostsContent -Entries $entriesToProcess
    } else {
        $newContent = Remove-HostEntry -CurrentContent $hostsContent -Entries $entriesToProcess
    }

    # Write updated content back to hosts file
    try {
        if ($PSCmdlet.ShouldProcess($hostsPath, "Update hosts file")) {
            Set-Content -Path $hostsPath -Value $newContent -Force -ErrorAction Stop
            Write-Information "Hosts file updated successfully!" -InformationAction Continue
            
            # Flush DNS cache
            Write-Verbose "Flushing DNS cache..."
            ipconfig /flushdns | Out-Null
            Write-Information "DNS cache flushed!" -InformationAction Continue
        }
    } catch {
        Write-Error "Failed to update hosts file: $_"
    }
}

<#
.SYNOPSIS
    Helper function to parse hosts file content.
#>
function ConvertFrom-HostsContent {
    param([string[]]$Content)
    
    $entries = @()
    foreach ($line in $Content) {
        # Skip empty lines and comments
        $trimmedLine = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmedLine) -or $trimmedLine.StartsWith('#')) {
            continue
        }

        # Parse IP and hostname (handle multiple hostnames per line)
        $parts = $trimmedLine -split '\s+' | Where-Object { $_ -ne '' }
        if ($parts.Count -ge 2) {
            $ip = $parts[0]
            # Add entry for each hostname on the line
            for ($i = 1; $i -lt $parts.Count; $i++) {
                $entries += [PSCustomObject]@{
                    IPAddress = $ip
                    Hostname = $parts[$i]
                }
            }
        }
    }
    return $entries
}

<#
.SYNOPSIS
    Helper function to add entries to hosts content.
#>
function Add-HostEntry {
    param(
        [string[]]$CurrentContent,
        [PSCustomObject[]]$Entries
    )

    $newContent = [System.Collections.ArrayList]@($CurrentContent)
    $addedCount = 0

    foreach ($entry in $Entries) {
        # Check if entry already exists
        $pattern = "^\s*$([regex]::Escape($entry.IPAddress))\s+$([regex]::Escape($entry.Hostname))\s*$"
        $exists = $CurrentContent | Where-Object { $_ -match $pattern }

        if (-not $exists) {
            # Add new entry
            $newLine = "$($entry.IPAddress)`t$($entry.Hostname)"
            $newContent.Add($newLine) | Out-Null
            Write-Information "Added: $newLine" -InformationAction Continue
            $addedCount++
        } else {
            Write-Verbose "Already exists: $($entry.IPAddress) $($entry.Hostname)"
        }
    }

    Write-Information "Total entries added: $addedCount" -InformationAction Continue
    return $newContent
}

<#
.SYNOPSIS
    Helper function to remove entries from hosts content.
#>
function Remove-HostEntry {
    param(
        [string[]]$CurrentContent,
        [PSCustomObject[]]$Entries
    )

    $newContent = [System.Collections.ArrayList]@()
    $removedCount = 0

    foreach ($line in $CurrentContent) {
        $shouldKeep = $true
        $trimmedLine = $line.Trim()

        # Keep empty lines and comments
        if ([string]::IsNullOrWhiteSpace($trimmedLine) -or $trimmedLine.StartsWith('#')) {
            $newContent.Add($line) | Out-Null
            continue
        }

        # Check if this line matches any entry to remove
        foreach ($entry in $Entries) {
            if ($entry.IPAddress) {
                # Remove by IP and hostname
                $pattern = "^\s*$([regex]::Escape($entry.IPAddress))\s+.*$([regex]::Escape($entry.Hostname)).*$"
            } else {
                # Remove by hostname only
                $pattern = "^\s*[\d\.]+\s+.*$([regex]::Escape($entry.Hostname)).*$"
            }

            if ($line -match $pattern) {
                $shouldKeep = $false
                Write-Information "Removed: $trimmedLine" -InformationAction Continue
                $removedCount++
                break
            }
        }

        if ($shouldKeep) {
            $newContent.Add($line) | Out-Null
        }
    }

    Write-Information "Total entries removed: $removedCount" -InformationAction Continue
    return $newContent
}

# Export functions
Export-ModuleMember -Function Set-FirewallRule, Remove-FirewallRule, Set-HostEntry

# Create aliases for backward compatibility
New-Alias -Name Delete-FirewallRule -Value Remove-FirewallRule
New-Alias -Name Set-Hosts -Value Set-HostEntry

# Export aliases
Export-ModuleMember -Alias Delete-FirewallRule, Set-Hosts


