
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

Set-StrictMode -Version Latest

function Get-ScoopRoot {
    if ($env:SCOOP -and $env:SCOOP.Trim()) { return $env:SCOOP }
    return (Join-Path $HOME 'scoop')
}

function Test-ScoopCoreOk {
    param([string]$ScoopRoot)

    $shimOk = Test-Path (Join-Path $ScoopRoot 'shims\scoop.ps1')
    $coreOk = Test-Path (Join-Path $ScoopRoot 'apps\scoop\current\bin\scoop.ps1')
    return ($shimOk -and $coreOk)
}

function Ensure-ScoopReady {
    param([string]$ScoopRoot)

    if (-not $ScoopRoot) { $ScoopRoot = Get-ScoopRoot }

    $env:SCOOP = $ScoopRoot
    [Environment]::SetEnvironmentVariable('SCOOP', $ScoopRoot, 'User')

    $shimDir = Join-Path $ScoopRoot 'shims'
    if ($env:Path -notlike "*$shimDir*") { $env:Path = "$shimDir;$env:Path" }

    # Kalau scoop core OK, JANGAN reinstall (biar gak bentrok buckets\main already exists)
    if (Test-ScoopCoreOk -ScoopRoot $ScoopRoot) { return }

    Write-Host "Scoop core missing/partial -> reinstall core saja (apps\\scoop + shim scoop)" -ForegroundColor Yellow

    # Hapus core scoop saja (app lain tetap aman)
    Remove-Item (Join-Path $ScoopRoot 'apps\scoop') -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $ScoopRoot 'shims\scoop*') -Force -ErrorAction SilentlyContinue

    try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

    Invoke-RestMethod -Uri 'https://get.scoop.sh' | Invoke-Expression

    # refresh PATH
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "User") + ";" +
                [Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($env:Path -notlike "*$shimDir*") { $env:Path = "$shimDir;$env:Path" }

    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        throw "Scoop tidak ditemukan setelah reinstall core. Cek $ScoopRoot dan PATH."
    }
}

function Parse-ScoopPackagesText {
    param([string]$Text)

    $tokens = New-Object System.Collections.Generic.List[string]
    foreach ($line in ($Text -split "`r?`n")) {
        $l = ($line -replace '#.*$', '').Trim()
        if (-not $l) { continue }

        # Kalau ada yang nyelip "scoop install ..." -> ambil argumennya saja
        if ($l -match '^\s*scoop\s+install\s+(.*)$') {
            $l = $Matches[1].Trim()
        }

        # Bullet "- git" / "* git"
        if ($l -match '^[\-\*]\s*(.+)$') {
            $l = $Matches[1].Trim()
        }

        # Split token
        foreach ($t in ($l -split '\s+')) {
            if ($t) { $tokens.Add($t) }
        }
    }
    return $tokens
}

function Install-ScoopPackagesSafe {
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$Packages,
        [string]$ScoopRoot
    )

    Ensure-ScoopReady -ScoopRoot $ScoopRoot

    # sanitize: buang '-', buang 'scoop', buang empty, dedupe
    $clean = $Packages |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and $_ -ne '-' -and $_ -ne '--' } |
        Where-Object { $_.ToLowerInvariant() -ne 'scoop' } |
        Select-Object -Unique

    if (-not $clean -or $clean.Count -eq 0) {
        Write-Host "No Scoop packages to install (after sanitize)." -ForegroundColor DarkYellow
        return
    }

    # install satu-satu biar gak ada token aneh kebaca
    foreach ($p in $clean) {
        Write-Host "Installing via Scoop: $p" -ForegroundColor Cyan
        & scoop install $p
    }
}

# Backward compatibility kalau kamu masih manggil ini
function Install-ScoopBinary {
    Ensure-ScoopReady
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