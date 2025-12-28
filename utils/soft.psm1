
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

    # Install Scoop directly (caller must ensure running as user, not admin)
    Write-Output "Installing Scoop..."
    
    # Set scoop directory
    $env:SCOOP = "$env:USERPROFILE\scoop"
    [System.Environment]::SetEnvironmentVariable('SCOOP', $env:SCOOP, 'User')
    
    # Check if Scoop directory exists (from failed installation)
    if (Test-Path $env:SCOOP) {
        Write-Warning "Detected previous Scoop installation at $env:SCOOP"
        Write-Output "Removing previous installation to start fresh..."
        try {
            Remove-Item -Path $env:SCOOP -Recurse -Force -ErrorAction Stop
            Write-Output "Previous installation removed successfully."
        } catch {
            Write-Warning "Could not remove previous installation: $_"
            Write-Warning "Installation may fail. Please manually remove $env:SCOOP and try again."
        }
    }
    
    # Download and run installer
    try {
        # Temporarily override Read-Host to handle Scoop prompts safely
        function global:Read-Host {
            param([string]$Prompt)

            # Intercept Scoop's "Are you sure? (yN)" prompt and return empty string (defaults to N)
            if ($Prompt -like 'Are you sure? (yN)*') {
                return ''
            }

            # For any other prompts, use the original Read-Host
            return Microsoft.PowerShell.Utility\Read-Host -Prompt $Prompt
        }

        Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression

        Write-Output "Scoop installation complete!"
    }
    finally {
        # Always restore the original Read-Host function
        Remove-Item function:\Read-Host -ErrorAction SilentlyContinue
    }
}

# this for download aria2 binary also no need params location
function Download-Aria2 {

    # replace this with current location script
    $aria2Path = Join-Path $PSScriptRoot "aria2"
    if (Test-Path $aria2Path) {
        Write-Output "Aria2 is already installed at $aria2Path."
        return
    }
    
    Write-Output "Downloading Aria2..."
    # 1.39.0 is likely a placeholder or future version, 1.37.0 is the latest stable release
    $aria2Url = "https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip"
    $aria2Zip = Join-Path $env:TEMP "aria2.zip"
    Invoke-DownloadFile -Url $aria2Url -OutputPath $aria2Zip -FollowRedirect
    
    Write-Output "Extracting Aria2..."
    $extractPath = Join-Path $env:TEMP "aria2_temp"
    
    # Ensure target directory exists
    if (!(Test-Path $aria2Path)) {
        New-Item -ItemType Directory -Path $aria2Path -Force
    }
    
    Expand-Archive -Path $aria2Zip -DestinationPath $extractPath -Force

    
    # Move files from the versioned subfolder to the target $aria2Path
    $subFolder = Get-ChildItem -Path $extractPath -Directory | Select-Object -First 1
    if ($subFolder) {
        Move-Item -Path "$($subFolder.FullName)\*" -Destination $aria2Path -Force
    }
    
    Remove-Item $aria2Zip -Force
    Remove-Item $extractPath -Recurse -Force

    
    Write-Output "Aria2 installation complete!"
}