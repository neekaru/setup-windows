# Powerful downloader module supporting Windows 7, 8, and modern Windows with headers, cookies, and output control

function Get-WindowsVersion {
    $osVersion = [System.Environment]::OSVersion.Version
    return @{
        Major = $osVersion.Major
        Minor = $osVersion.Minor
        Build = $osVersion.Build
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
        [switch]$FollowRedirect,
        [int]$TimeoutSeconds = 30,
        [switch]$UseBasicParsing,
        [string]$UserAgent = "PowerShell/Downloader"
    )

    try {
        $winVersion = Get-WindowsVersion
        $isOldWindows = ($winVersion.Major -eq 6 -and $winVersion.Minor -lt 2)

        Write-Host "Downloading from: $Url"
        Write-Host "Output path: $OutputPath"
        Write-Host "Windows version: $($winVersion.Major).$($winVersion.Minor)"

        if ($isOldWindows) {
            # For Windows 7 and older - use WebClient
            Write-Host "Using .NET WebClient for legacy Windows support"
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
            Write-Host "Using Invoke-WebRequest for modern Windows support"

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
                $params['MaximumRedirection'] = 5
            } else {
                $params['MaximumRedirection'] = 0
            }

            Invoke-WebRequest @params -ErrorAction Stop
        }

        if (Test-Path $OutputPath) {
            $fileSize = (Get-Item $OutputPath).Length
            Write-Host "Download completed successfully!"
            Write-Host "File size: $fileSize bytes"
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
        Write-Host "Download attempt $($retryCount + 1) of $MaxRetries"
        
        $success = Invoke-DownloadFile `
            -Url $Url `
            -OutputPath $OutputPath `
            -Headers $Headers `
            -Cookies $Cookies `
            -TimeoutSeconds $TimeoutSeconds `
            -FollowRedirect:$FollowRedirect

        if (-not $success -and $retryCount -lt ($MaxRetries - 1)) {
            Write-Host "Retrying in $RetryDelaySeconds seconds..."
            Start-Sleep -Seconds $RetryDelaySeconds
        }

        $retryCount++
    }

    if ($success) {
        Write-Host "Download completed successfully after $retryCount attempt(s)"
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
            Write-Host "Cookies saved to: $OutputFile"
            return $true
        } else {
            Write-Host "No cookies found in response"
            return $false
        }
    } catch {
        Write-Error "Failed to save cookies: $_"
        return $false
    }
}

function Get-HttpHeaders {
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

Export-ModuleMember -Function Invoke-DownloadFile, Invoke-DownloadWithRetry, Get-DownloadSpeed, Save-CookiesFromResponse, Get-HttpHeaders
