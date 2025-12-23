function Set-ExecutionPolicyWrapper {
    [CmdletBinding()]
    param(
        [ValidateSet('Bypass', 'RemoteSigned', 'AllSigned', 'Restricted', 'Unrestricted', 'Default')]
        [string]$ExecutionPolicy = 'Bypass',

        [ValidateSet('Process', 'CurrentUser', 'LocalMachine', 'UserPolicy', 'MachinePolicy')]
        [string]$Scope = 'Process',

        [bool]$RelaunchIfNeeded = $true
    )

    $current = Get-ExecutionPolicy -Scope $Scope
    if ($current -eq $ExecutionPolicy) {
        return $true
    }

    try {
        Set-ExecutionPolicy -ExecutionPolicy $ExecutionPolicy -Scope $Scope -Force -ErrorAction Stop
    } catch {
        Write-Verbose "Set-ExecutionPolicy failed: $_"
    }

    $current = Get-ExecutionPolicy -Scope $Scope
    if ($current -ne $ExecutionPolicy) {
        $versionInfo = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue
        $editionId = $versionInfo.EditionID
        $productName = $versionInfo.ProductName
        $isIoT = ($editionId -match 'IoT') -or ($productName -match 'IoT')

        if ($ExecutionPolicy -eq 'Bypass' -and $Scope -eq 'Process' -and $RelaunchIfNeeded) {
            $relaunchFlag = 'SETUP_WINDOWS_EP_RELAUNCH'
            if (-not [Environment]::GetEnvironmentVariable($relaunchFlag)) {
                $callStack = Get-PSCallStack
                $scriptFrame = $callStack | Where-Object { $_.ScriptName -and ($_.ScriptName -notmatch '\.psm1$') } | Select-Object -First 1
                $scriptPath = $null
                if ($scriptFrame) {
                    $scriptPath = $scriptFrame.ScriptName
                }

                if ($scriptPath -and (Test-Path $scriptPath)) {
                    [Environment]::SetEnvironmentVariable($relaunchFlag, '1', 'Process')
                    $argsList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $scriptPath)
                    if ($global:args -and $global:args.Count -gt 0) {
                        $argsList += $global:args
                    }

                    Start-Process -FilePath 'powershell' -ArgumentList $argsList
                    exit 0
                }
            }
        }

        if ($ExecutionPolicy -eq 'Bypass' -and $Scope -eq 'Process' -and $isIoT) {
            Write-Warning "Execution policy is still '$current'. On Windows IoT, re-launch PowerShell with `powershell -ep B`."
        } else {
            Write-Warning "Execution policy is still '$current'. Re-launch PowerShell with `-ExecutionPolicy $ExecutionPolicy` if needed."
        }

        return $false
    }

    return $true
}

# this only for getting are we on proccess or what
function Get-ExecutionPolicyWrapper {
    [CmdletBinding()]
    param(
        [ValidateSet('Process', 'CurrentUser', 'LocalMachine', 'UserPolicy',
        'MachinePolicy')]
        [string]$Scope = 'Process'
    )
    return Get-ExecutionPolicy -Scope $Scope
}

Export-ModuleMember -Function Set-ExecutionPolicyWrapper, Get-ExecutionPolicyWrapper

New-Alias -Name Set-ExecutionPolicySafe -Value Set-ExecutionPolicyWrapper
New-Alias -Name Get-ExecutionPolicySafe -Value Get-ExecutionPolicyWrapper

Export-ModuleMember -Alias Set-ExecutionPolicySafe, Get-ExecutionPolicySafe
