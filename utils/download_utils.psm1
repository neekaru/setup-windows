# Powerful downloader module supporting Windows 7, 8, and modern Windows with headers, cookies, and output control

function Get-WindowsVersion {
    $osVersion = [System.Environment]::OSVersion.Version
    return @{
        Major = $osVersion.Major
        Minor = $osVersion.Minor
        Build = $osVersion.Build
    }
}

function Get-Aria2Path {
    # Check for aria2c.exe in bin folder relative to this module
    $binPath = Join-Path (Split-Path $PSScriptRoot -Parent) "bin"
    $aria2Exe = Join-Path $binPath "aria2c.exe"
    
    if (Test-Path $aria2Exe) {
        return $aria2Exe
    }
    
    # Also check in utils folder for backward compatibility
    $utilsAria2 = Join-Path $PSScriptRoot "aria2\aria2c.exe"
    if (Test-Path $utilsAria2) {
        return $utilsAria2
    }
    
    return $null
}

function Test-IsGitHubUrl {
    param([string]$Url)
    return $Url -match "^https?://(www\.)?github\.com"
}

function Invoke-Aria2Download {
    param (
        [Parameter(Mandatory)]
        [string]$Url,

        [Parameter(Mandatory)]
        [string]$OutputPath,

        [string]$Aria2Path,
        [hashtable]$Headers,
        [string]$UserAgent = "Wget/1.21.3",
        [int]$MaxConnections = 16,
        [int]$SplitCount = 16
    )

    $outputDir = Split-Path $OutputPath -Parent
    $outputFile = Split-Path $OutputPath -Leaf

    # Build aria2c arguments
    $args = @(
        "--dir=`"$outputDir`"",
        "--out=`"$outputFile`"",
        "--max-connection-per-server=$MaxConnections",
        "--split=$SplitCount",
        "--min-split-size=1M",
        "--user-agent=`"$UserAgent`"",
        "--continue=true",
        "--allow-overwrite=true",
        "--max-redirection=50",
        "`"$Url`""
    )

    # Add custom headers if provided
    if ($Headers) {
        foreach ($header in $Headers.GetEnumerator()) {
            $args += "--header=`"$($header.Key): $($header.Value)`""
        }
    }

    Write-Verbose "Using aria2c for download: $Url"
    Write-Verbose "Output: $OutputPath"

    try {
        $process = Start-Process -FilePath $Aria2Path -ArgumentList $args -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -eq 0 -and (Test-Path $OutputPath)) {
            $fileSize = (Get-Item $OutputPath).Length
            Write-Verbose "aria2c download completed successfully!"
            Write-Verbose "File size: $fileSize bytes"
            return $true
        } else {
            Write-Warning "aria2c download failed with exit code: $($process.ExitCode)"
            return $false
        }
    } catch {
        Write-Warning "aria2c error: $_"
        return $false
    }
}

function Invoke-DownloadFile {
    param (
        [Parameter(Mandatory)]
        [string]$Url,

        [Parameter(Mandatory)]
        [string]$OutputPath,

        [hashtable]$Headers,
        [hashtable]$Cookies,
        [switch]$FollowRedirect = $true,
        [int]$TimeoutSeconds = 30,
        [switch]$UseBasicParsing,
        [string]$UserAgent = "Wget/1.21.3",
        [switch]$ForcePowerShell
    )

    try {
        $winVersion = Get-WindowsVersion
        $isOldWindows = ($winVersion.Major -eq 6 -and $winVersion.Minor -lt 2)

        Write-Verbose "Downloading from: $Url"
        Write-Verbose "Output path: $OutputPath"
        Write-Verbose "Windows version: $($winVersion.Major).$($winVersion.Minor)"

        # Try aria2c for non-GitHub URLs (GitHub works fine with PowerShell)
        $aria2Path = Get-Aria2Path
        $isGitHub = Test-IsGitHubUrl -Url $Url
        
        if ($aria2Path -and -not $isGitHub -and -not $ForcePowerShell -and -not $Cookies) {
            Write-Verbose "aria2c available, using it for faster download"
            $aria2Result = Invoke-Aria2Download -Url $Url -OutputPath $OutputPath -Aria2Path $aria2Path -Headers $Headers -UserAgent $UserAgent
            
            if ($aria2Result) {
                return $true
            }
            
            Write-Warning "aria2c failed, falling back to PowerShell method"
        }

        if ($isOldWindows) {
            # For Windows 7 and older - use WebClient
            Write-Verbose "Using .NET WebClient for legacy Windows support"
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("User-Agent", $UserAgent)

            if ($Headers) {
                foreach ($header in $Headers.GetEnumerator()) {
                    $webClient.Headers.Add($header.Key, $header.Value)
                }
            }

            if ($Cookies) {
                $cookieContainer = New-Object System.Net.CookieContainer
                foreach ($cookie in $Cookies.GetEnumerator()) {
                    $uri = New-Object System.Uri($Url)
                    $c = New-Object System.Net.Cookie($cookie.Key, $cookie.Value)
                    $cookieContainer.Add($uri, $c)
                }
                $webClient.CookieContainer = $cookieContainer
            }

            $webClient.DownloadFile($Url, $OutputPath)
            $webClient.Dispose()
        } else {
            # For Windows 8 and newer - use Invoke-WebRequest
            Write-Verbose "Using Invoke-WebRequest for modern Windows support"

            $params = @{
                Uri             = $Url
                OutFile         = $OutputPath
                UserAgent       = $UserAgent
                TimeoutSec      = $TimeoutSeconds
                UseBasicParsing = $UseBasicParsing
            }

            if ($Headers) {
                $params['Headers'] = $Headers
            }

            if ($Cookies) {
                $sessionCookie = New-Object Microsoft.PowerShell.Commands.WebRequestSession
                foreach ($cookie in $Cookies.GetEnumerator()) {
                    $sessionCookie.Cookies.Add((New-Object System.Net.Cookie($cookie.Key, $cookie.Value)))
                }
                $params['WebSession'] = $sessionCookie
            }

            if ($FollowRedirect) { 
                $params['MaximumRedirection'] = 50
            } else {
                $params['MaximumRedirection'] = 0
            }

            Invoke-WebRequest @params -ErrorAction Stop
        }

        if (Test-Path $OutputPath) {
            $fileSize = (Get-Item $OutputPath).Length
            if ($fileSize -lt 100) { # Likely an error page or empty file
                Write-Error "Download failed: File is too small ($fileSize bytes). It might be an error page."
                return $false
            }
            Write-Verbose "Download completed successfully!"
            Write-Verbose "File size: $fileSize bytes"
            return $true
        } else {
            Write-Error "Download failed: Output file not created"
            return $false
        }
    } catch {
        Write-Error "Download error: $_"
        return $false
    }
}

function Invoke-DownloadWithRetry {
    param (
        [Parameter(Mandatory)]
        [string]$Url,

        [Parameter(Mandatory)]
        [string]$OutputPath,

        [hashtable]$Headers,
        [hashtable]$Cookies,
        [int]$MaxRetries = 3,
        [int]$RetryDelaySeconds = 5,
        [int]$TimeoutSeconds = 30,
        [switch]$FollowRedirect
    )

    $retryCount = 0
    $success = $false

    while ($retryCount -lt $MaxRetries -and -not $success) {
        Write-Verbose "Download attempt $($retryCount + 1) of $MaxRetries"
        
        $success = Invoke-DownloadFile `
            -Url $Url `
            -OutputPath $OutputPath `
            -Headers $Headers `
            -Cookies $Cookies `
            -TimeoutSeconds $TimeoutSeconds `
            -FollowRedirect:$FollowRedirect

        if (-not $success -and $retryCount -lt ($MaxRetries - 1)) {
            Write-Verbose "Retrying in $RetryDelaySeconds seconds..."
            Start-Sleep -Seconds $RetryDelaySeconds
        }

        $retryCount++
    }

    if ($success) {
        Write-Verbose "Download completed successfully after $retryCount attempt(s)"
        return $true
    } else {
        Write-Error "Download failed after $MaxRetries attempts"
        return $false
    }
}

function Get-DownloadSpeed {
    param (
        [Parameter(Mandatory)]
        [string]$FilePath
    )

    if (Test-Path $FilePath) {
        $file = Get-Item $FilePath
        return @{
            FileName   = $file.Name
            SizeBytes  = $file.Length
            SizeMB     = [math]::Round($file.Length / 1MB, 2)
            Modified   = $file.LastWriteTime
        }
    } else {
        Write-Error "File not found: $FilePath"
        return $null
    }
}

function Save-CookiesFromResponse {
    param (
        [Parameter(Mandatory)]
        [object]$Response,

        [string]$OutputFile
    )

    try {
        if ($Response.Headers.ContainsKey('Set-Cookie')) {
            $cookies = $Response.Headers['Set-Cookie']
            $cookies | Out-File -FilePath $OutputFile -Force
            Write-Verbose "Cookies saved to: $OutputFile"
            return $true
        } else {
            Write-Verbose "No cookies found in response"
            return $false
        }
    } catch {
        Write-Error "Failed to save cookies: $_"
        return $false
    }
}

function Get-HttpHeader {
    param (
        [Parameter(Mandatory)]
        [string]$Url,

        [hashtable]$CustomHeaders,
        [hashtable]$Cookies,
        [string]$UserAgent = "PowerShell/Downloader"
    )

    try {
        $winVersion = Get-WindowsVersion
        $isOldWindows = ($winVersion.Major -eq 6 -and $winVersion.Minor -lt 2)

        if ($isOldWindows) {
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("User-Agent", $UserAgent)

            if ($CustomHeaders) {
                foreach ($header in $CustomHeaders.GetEnumerator()) {
                    $webClient.Headers.Add($header.Key, $header.Value)
                }
            }

            $response = $webClient.DownloadString($Url)
            return $webClient.ResponseHeaders
        } else {
            $params = @{
                Uri         = $Url
                UserAgent   = $UserAgent
                Method      = 'HEAD'
            }

            if ($CustomHeaders) {
                $params['Headers'] = $CustomHeaders
            }

            if ($Cookies) {
                $sessionCookie = New-Object Microsoft.PowerShell.Commands.WebRequestSession
                foreach ($cookie in $Cookies.GetEnumerator()) {
                    $sessionCookie.Cookies.Add((New-Object System.Net.Cookie($cookie.Key, $cookie.Value)))
                }
                $params['WebSession'] = $sessionCookie
            }

            $response = Invoke-WebRequest @params -ErrorAction Stop
            return $response.Headers
        }
    } catch {
        Write-Error "Failed to get headers: $_"
        return $null
    }
}

Export-ModuleMember -Function Invoke-DownloadFile, Invoke-DownloadWithRetry, Get-DownloadSpeed, Save-CookiesFromResponse, Get-HttpHeader, Invoke-Aria2Download, Get-Aria2Path, Test-IsGitHubUrl


# Create aliases for backward compatibility and common alternative names
New-Alias -Name Download-File -Value Invoke-DownloadFile
New-Alias -Name Download-FileWithRetry -Value Invoke-DownloadWithRetry
New-Alias -Name Get-FileInfo -Value Get-DownloadSpeed
New-Alias -Name Save-Cookies -Value Save-CookiesFromResponse
New-Alias -Name Get-Headers -Value Get-HttpHeader

# Export aliases
Export-ModuleMember -Alias Download-File, Download-FileWithRetry, Get-FileInfo, Save-Cookies, Get-Headers
