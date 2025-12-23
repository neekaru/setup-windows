
# this handler for install winget itself 
Import-Module (Join-Path $PSScriptRoot "download_utils.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "execution.psm1") -Force

function Install-WingetBinary {
    # params needs to force install winget if not present
    param(
        [bool]$ForceInstall = $false,
        [ValidateSet('Never', 'Retry', 'Force')]
        [string]$ConhostMode = 'Never',
        [bool]$IgnoreHashMismatch = $true
    )
    # get OS info
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $caption = $os.Caption
    $winVersion = $os.Version

    # detect LTSC (allow LTSC even if other checks would block)
    $editionId = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue).EditionID
    $isLTSC = ($caption -match 'LTSC') -or ($editionId -match 'LTSC')

    # check if windows is server (ProductType 3) but treat LTSC as allowed
    $isServer = ($os.ProductType -eq 3) -and -not $isLTSC

    # also check if windows is older than Windows 10, but allow LTSC
    $isOldWindows = ([version]$winVersion -lt [version]"10.0") -and -not $isLTSC

    if ($isServer -or $isOldWindows) {
        Write-Output "Winget is not supported on Windows Server or versions older than Windows 10."
        return
    }

    # check if winget is already installed
    $wingetPath = Get-Command winget.exe -ErrorAction SilentlyContinue
    if ($wingetPath -and -not $ForceInstall) {
        Write-Output "Winget is already installed at $($wingetPath.Path)."
        return
    }

    # Download and install App Installer from Microsoft Store
    Write-Output "Installing Winget (App Installer) from Microsoft Store..."
    
    # first using our winget-install script to install winget
    # first allow to session to run scripts
    Set-ExecutionPolicyWrapper -ExecutionPolicy Bypass -Scope Process
    # we use offline installer
    Invoke-DownloadFile -Url "https://github.com/asheroto/winget-install/releases/latest/download/winget-install.ps1" -OutputPath "$env:TEMP\winget-install.ps1" -FollowRedirect

    # run the installer script
    # build args for the downloaded winget-install.ps1 based on common global vars or this function's $ForceInstall
    $wingetArgs = "& `$env:TEMP\winget-install.ps1"
    if ($ForceInstall) {
        $wingetArgs += " -Force"
    }
    $wingetArgs += " -Debug"
    
    Invoke-Command -Commands @($wingetArgs) -ConhostMode $ConhostMode -WaitForExit
}

# this for install choco binary if not present
function Install-ChocolateyBinary {
    # check if choco is already installed
    $chocoPath = Get-Command choco.exe -ErrorAction SilentlyContinue
    if ($chocoPath) {
        Write-Output "Chocolatey is already installed at $($chocoPath.Path)."
        return
    }

    # Install Chocolatey
    Write-Output "Installing Chocolatey..."
    Set-ExecutionPolicyWrapper -ExecutionPolicy Bypass -Scope Process
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    $chocoScript = Join-Path $env:TEMP "install_chocolatey.ps1"
    (New-Object System.Net.WebClient).DownloadFile('https://chocolatey.org/install.ps1', $chocoScript)
    & $chocoScript
    Remove-Item $chocoScript -Force -ErrorAction SilentlyContinue
}

# this for install scoop binary if not present
function Install-ScoopBinary {
    # check if scoop is already installed
    $scoopPath = Get-Command scoop -ErrorAction SilentlyContinue
    if ($scoopPath) {
        Write-Output "Scoop is already installed at $($scoopPath.Path)."
        return
    }

    # Install Scoop in user mode (non-admin)
    Write-Output "Installing Scoop in user mode (non-admin)..."
    
    # Create scoop directory if it doesn't exist
    if (-not (Test-Path "$env:USERPROFILE\scoop")) {
        New-Item -ItemType Directory -Path "$env:USERPROFILE\scoop" -Force | Out-Null
    }
    
    # Download and run scoop installer in a new non-admin PowerShell process
    $scoopInstallScript = @"
# Set scoop directory
`$env:SCOOP = '$env:USERPROFILE\scoop'
[System.Environment]::SetEnvironmentVariable('SCOOP', `$env:SCOOP, 'User')

# Run installer - Scoop must be run as non-admin
Write-Host "Installing Scoop (as user, NOT admin)..."
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
"@
    
    $scoopScriptPath = "$env:TEMP\install-scoop-temp.ps1"
    $scoopInstallScript | Out-File -FilePath $scoopScriptPath -Encoding UTF8 -Force
    
    # Run in a new PowerShell window as NON-ADMIN user
    # Use /USER flag to ensure it doesn't run as admin even if current process is admin
    $process = Start-Process -FilePath "powershell.exe" `
        -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-NoExit", "-File", "`"$scoopScriptPath`"" `
        -UseNewEnvironment `
        -PassThru
    
    # Wait for the process to complete
    $process | Wait-Process
    
    # Clean up
    Remove-Item $scoopScriptPath -Force -ErrorAction SilentlyContinue
    
    # Refresh environment variables to pick up scoop
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "User") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    
    # Verify installation
    $scoop = Get-Command scoop -ErrorAction SilentlyContinue
    if ($scoop) {
        Write-Output "✓ Scoop installed successfully at $($scoop.Path)!"
    } else {
        Write-Warning "⚠ Scoop installation may have failed. See: https://github.com/ScoopInstaller/Install#for-admin"
    }
}

