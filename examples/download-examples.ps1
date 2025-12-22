<#
.SYNOPSIS
    Examples for using download_utils.psm1 module functions.

.DESCRIPTION
    This file contains practical examples for downloading files with advanced features
    like headers, cookies, retries, and Windows version compatibility.
#>

# Import the download utilities module
Import-Module ..\utils\download_utils.psm1 -Force

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Download Utilities Examples" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================
# BASIC DOWNLOAD EXAMPLES
# ============================================

Write-Host "--- Basic Download Examples ---" -ForegroundColor Yellow
Write-Host ""

# Example 1: Simple file download
Write-Host "Example 1: Download a single file" -ForegroundColor Green
Write-Host 'Invoke-DownloadFile -Url "https://example.com/file.zip" -OutputPath "C:\Downloads\file.zip"'
# Invoke-DownloadFile -Url "https://example.com/file.zip" -OutputPath "C:\Downloads\file.zip"

Write-Host ""

# Example 2: Download with custom user agent
Write-Host "Example 2: Download with custom User-Agent" -ForegroundColor Green
Write-Host 'Invoke-DownloadFile -Url "https://example.com/file.zip" -OutputPath ".\file.zip" -UserAgent "Mozilla/5.0"'
# Invoke-DownloadFile -Url "https://example.com/file.zip" -OutputPath ".\file.zip" -UserAgent "Mozilla/5.0"

Write-Host ""

# Example 3: Download with timeout
Write-Host "Example 3: Download with custom timeout" -ForegroundColor Green
Write-Host 'Invoke-DownloadFile -Url "https://example.com/largefile.zip" -OutputPath ".\large.zip" -TimeoutSeconds 60'
# Invoke-DownloadFile -Url "https://example.com/largefile.zip" -OutputPath ".\large.zip" -TimeoutSeconds 60

Write-Host ""

# ============================================
# ADVANCED DOWNLOAD EXAMPLES
# ============================================

Write-Host "--- Advanced Download Examples ---" -ForegroundColor Yellow
Write-Host ""

# Example 4: Download with custom headers
Write-Host "Example 4: Download with custom HTTP headers" -ForegroundColor Green
Write-Host '$headers = @{'
Write-Host '    "Authorization" = "Bearer YOUR_TOKEN"'
Write-Host '    "Accept" = "application/octet-stream"'
Write-Host '}'
Write-Host 'Invoke-DownloadFile -Url "https://api.example.com/file" -OutputPath ".\file.bin" -Headers $headers'
# $headers = @{
#     "Authorization" = "Bearer YOUR_TOKEN"
#     "Accept" = "application/octet-stream"
# }
# Invoke-DownloadFile -Url "https://api.example.com/file" -OutputPath ".\file.bin" -Headers $headers

Write-Host ""

# Example 5: Download with cookies
Write-Host "Example 5: Download with cookies" -ForegroundColor Green
Write-Host '$cookies = @{'
Write-Host '    "session_id" = "abc123xyz"'
Write-Host '    "user_token" = "token456"'
Write-Host '}'
Write-Host 'Invoke-DownloadFile -Url "https://example.com/protected/file.zip" -OutputPath ".\file.zip" -Cookies $cookies'
# $cookies = @{
#     "session_id" = "abc123xyz"
#     "user_token" = "token456"
# }
# Invoke-DownloadFile -Url "https://example.com/protected/file.zip" -OutputPath ".\file.zip" -Cookies $cookies

Write-Host ""

# Example 6: Download with redirect following
Write-Host "Example 6: Download with redirect following" -ForegroundColor Green
Write-Host 'Invoke-DownloadFile -Url "https://short.url/file" -OutputPath ".\file.zip" -FollowRedirect'
# Invoke-DownloadFile -Url "https://short.url/file" -OutputPath ".\file.zip" -FollowRedirect

Write-Host ""

# ============================================
# RETRY MECHANISM EXAMPLES
# ============================================

Write-Host "--- Download with Retry Examples ---" -ForegroundColor Yellow
Write-Host ""

# Example 7: Download with automatic retry
Write-Host "Example 7: Download with automatic retry (3 attempts)" -ForegroundColor Green
Write-Host 'Invoke-DownloadWithRetry -Url "https://example.com/file.zip" -OutputPath ".\file.zip" -MaxRetries 3'
# Invoke-DownloadWithRetry -Url "https://example.com/file.zip" -OutputPath ".\file.zip" -MaxRetries 3

Write-Host ""

# Example 8: Download with custom retry delay
Write-Host "Example 8: Download with custom retry delay" -ForegroundColor Green
Write-Host 'Invoke-DownloadWithRetry -Url "https://example.com/file.zip" -OutputPath ".\file.zip" -MaxRetries 5 -RetryDelaySeconds 10'
# Invoke-DownloadWithRetry -Url "https://example.com/file.zip" -OutputPath ".\file.zip" -MaxRetries 5 -RetryDelaySeconds 10

Write-Host ""

# Example 9: Retry with headers and cookies
Write-Host "Example 9: Retry download with headers and cookies" -ForegroundColor Green
Write-Host '$headers = @{ "Authorization" = "Bearer TOKEN" }'
Write-Host '$cookies = @{ "session" = "xyz123" }'
Write-Host 'Invoke-DownloadWithRetry -Url "https://api.example.com/file" -OutputPath ".\file.zip" -Headers $headers -Cookies $cookies -MaxRetries 3'
# $headers = @{ "Authorization" = "Bearer TOKEN" }
# $cookies = @{ "session" = "xyz123" }
# Invoke-DownloadWithRetry -Url "https://api.example.com/file" -OutputPath ".\file.zip" -Headers $headers -Cookies $cookies -MaxRetries 3

Write-Host ""

# ============================================
# UTILITY FUNCTIONS EXAMPLES
# ============================================

Write-Host "--- Utility Functions Examples ---" -ForegroundColor Yellow
Write-Host ""

# Example 10: Get file information after download
Write-Host "Example 10: Get download speed/file info" -ForegroundColor Green
Write-Host 'Invoke-DownloadFile -Url "https://example.com/file.zip" -OutputPath ".\file.zip"'
Write-Host '$fileInfo = Get-DownloadSpeed -FilePath ".\file.zip"'
Write-Host 'Write-Host "File: $($fileInfo.FileName)"'
Write-Host 'Write-Host "Size: $($fileInfo.SizeMB) MB"'
# Invoke-DownloadFile -Url "https://example.com/file.zip" -OutputPath ".\file.zip"
# $fileInfo = Get-DownloadSpeed -FilePath ".\file.zip"
# Write-Host "File: $($fileInfo.FileName)"
# Write-Host "Size: $($fileInfo.SizeMB) MB"

Write-Host ""

# Example 11: Get HTTP headers before downloading
Write-Host "Example 11: Get HTTP headers (check file size before download)" -ForegroundColor Green
Write-Host '$headers = Get-HttpHeader -Url "https://example.com/largefile.zip"'
Write-Host 'if ($headers["Content-Length"]) {'
Write-Host '    $sizeMB = [math]::Round($headers["Content-Length"] / 1MB, 2)'
Write-Host '    Write-Host "File size: $sizeMB MB"'
Write-Host '}'
# $headers = Get-HttpHeader -Url "https://example.com/largefile.zip"
# if ($headers["Content-Length"]) {
#     $sizeMB = [math]::Round($headers["Content-Length"] / 1MB, 2)
#     Write-Host "File size: $sizeMB MB"
# }

Write-Host ""

# Example 12: Save cookies from response
Write-Host "Example 12: Save cookies from response" -ForegroundColor Green
Write-Host '$response = Invoke-WebRequest -Uri "https://example.com/login"'
Write-Host 'Save-CookiesFromResponse -Response $response -OutputFile ".\cookies.txt"'
# $response = Invoke-WebRequest -Uri "https://example.com/login"
# Save-CookiesFromResponse -Response $response -OutputFile ".\cookies.txt"

Write-Host ""

# ============================================
# PRACTICAL SCENARIOS
# ============================================

Write-Host "--- Practical Scenarios ---" -ForegroundColor Yellow
Write-Host ""

# Scenario 1: Download installer with retry
Write-Host "Scenario 1: Download Software Installer with Retry" -ForegroundColor Magenta
Write-Host "# Download a software installer with automatic retry"
Write-Host '$url = "https://example.com/software-installer.exe"'
Write-Host '$output = "C:\Temp\installer.exe"'
Write-Host 'Invoke-DownloadWithRetry -Url $url -OutputPath $output -MaxRetries 3 -Verbose'

Write-Host ""

# Scenario 2: Download from GitHub releases
Write-Host "Scenario 2: Download from GitHub Releases" -ForegroundColor Magenta
Write-Host "# Download latest release from GitHub"
Write-Host '$headers = @{ "Accept" = "application/octet-stream" }'
Write-Host '$url = "https://github.com/user/repo/releases/download/v1.0/app.zip"'
Write-Host 'Invoke-DownloadFile -Url $url -OutputPath ".\app.zip" -Headers $headers -FollowRedirect'

Write-Host ""

# Scenario 3: Download with authentication
Write-Host "Scenario 3: Download Protected File with Authentication" -ForegroundColor Magenta
Write-Host "# Download file that requires authentication"
Write-Host '$headers = @{'
Write-Host '    "Authorization" = "Bearer YOUR_API_TOKEN"'
Write-Host '    "User-Agent" = "MyApp/1.0"'
Write-Host '}'
Write-Host 'Invoke-DownloadWithRetry -Url "https://api.example.com/files/protected.zip" -OutputPath ".\protected.zip" -Headers $headers -MaxRetries 3'

Write-Host ""

# Scenario 4: Batch download multiple files
Write-Host "Scenario 4: Batch Download Multiple Files" -ForegroundColor Magenta
Write-Host "# Download multiple files with retry"
Write-Host '$files = @('
Write-Host '    @{ Url = "https://example.com/file1.zip"; Output = ".\file1.zip" }'
Write-Host '    @{ Url = "https://example.com/file2.zip"; Output = ".\file2.zip" }'
Write-Host '    @{ Url = "https://example.com/file3.zip"; Output = ".\file3.zip" }'
Write-Host ')'
Write-Host 'foreach ($file in $files) {'
Write-Host '    Write-Host "Downloading: $($file.Url)"'
Write-Host '    Invoke-DownloadWithRetry -Url $file.Url -OutputPath $file.Output -MaxRetries 3'
Write-Host '}'

Write-Host ""

# Scenario 5: Download and verify size
Write-Host "Scenario 5: Download and Verify File Size" -ForegroundColor Magenta
Write-Host "# Check file size before downloading"
Write-Host '$url = "https://example.com/largefile.zip"'
Write-Host '$headers = Get-HttpHeader -Url $url'
Write-Host 'if ($headers["Content-Length"]) {'
Write-Host '    $sizeMB = [math]::Round($headers["Content-Length"] / 1MB, 2)'
Write-Host '    Write-Host "File size: $sizeMB MB"'
Write-Host '    if ($sizeMB -lt 100) {'
Write-Host '        Invoke-DownloadFile -Url $url -OutputPath ".\file.zip"'
Write-Host '    } else {'
Write-Host '        Write-Host "File too large, skipping download"'
Write-Host '    }'
Write-Host '}'

Write-Host ""
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "End of Examples" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "NOTE: Uncomment the lines you want to execute!" -ForegroundColor Yellow
Write-Host "TIP: Use -Verbose flag for detailed output!" -ForegroundColor Cyan
