<#
.SYNOPSIS
    Examples for using network.psm1 module functions.

.DESCRIPTION
    This file contains practical examples for managing Windows Firewall rules
    and hosts file entries using the network.psm1 module.

.NOTES
    - Firewall operations require Administrator privileges
    - Hosts file operations require Administrator privileges
    - Always test with non-critical applications first
#>

# Import the network module
Import-Module ..\utils\network.psm1 -Force

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Network Module Examples" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================
# FIREWALL RULES EXAMPLES
# ============================================

Write-Host "--- Firewall Rules Examples ---" -ForegroundColor Yellow
Write-Host ""

# Example 1: Block a single application (both inbound and outbound)
Write-Host "Example 1: Block a single executable" -ForegroundColor Green
Write-Host 'Set-FirewallRule -Path "C:\Program Files\MyApp\app.exe" -Action Block -Direction All'
# Set-FirewallRule -Path "C:\Program Files\MyApp\app.exe" -Action Block -Direction All

Write-Host ""

# Example 2: Block all executables in a folder (outbound only)
Write-Host "Example 2: Block all executables in a folder (outbound)" -ForegroundColor Green
Write-Host 'Set-FirewallRule -Path "C:\Program Files\MyApp" -Action Block -Direction Outbound'
# Set-FirewallRule -Path "C:\Program Files\MyApp" -Action Block -Direction Outbound

Write-Host ""

# Example 3: Allow specific application (inbound only)
Write-Host "Example 3: Allow inbound traffic for an application" -ForegroundColor Green
Write-Host 'Set-FirewallRule -Path "C:\Program Files\MyServer\server.exe" -Action Allow -Direction Inbound'
# Set-FirewallRule -Path "C:\Program Files\MyServer\server.exe" -Action Allow -Direction Inbound

Write-Host ""

# Example 4: Block Chrome browser (common use case)
Write-Host "Example 4: Block Google Chrome" -ForegroundColor Green
Write-Host 'Set-FirewallRule -Path "C:\Program Files\Google\Chrome\Application\chrome.exe" -Action Block -Direction All'
# Set-FirewallRule -Path "C:\Program Files\Google\Chrome\Application\chrome.exe" -Action Block -Direction All

Write-Host ""

# Example 5: Block all browsers in a folder
Write-Host "Example 5: Block all browsers in Mozilla Firefox folder" -ForegroundColor Green
Write-Host 'Set-FirewallRule -Path "C:\Program Files\Mozilla Firefox" -Action Block -Direction All'
# Set-FirewallRule -Path "C:\Program Files\Mozilla Firefox" -Action Block -Direction All

Write-Host ""

# Example 6: Delete firewall rules for a single application
Write-Host "Example 6: Delete firewall rules for an application" -ForegroundColor Green
Write-Host 'Delete-FirewallRule -Path "C:\Program Files\MyApp\app.exe" -Action Block -Direction All'
# Delete-FirewallRule -Path "C:\Program Files\MyApp\app.exe" -Action Block -Direction All

Write-Host ""

# Example 7: Delete firewall rules for all apps in a folder
Write-Host "Example 7: Delete firewall rules for folder" -ForegroundColor Green
Write-Host 'Delete-FirewallRule -Path "C:\Program Files\MyApp" -Action Block -Direction Outbound'
# Delete-FirewallRule -Path "C:\Program Files\MyApp" -Action Block -Direction Outbound

Write-Host ""
Write-Host ""

# ============================================
# HOSTS FILE MANAGEMENT EXAMPLES
# ============================================

Write-Host "--- Hosts File Management Examples ---" -ForegroundColor Yellow
Write-Host ""

# Example 1: Add a single host entry
Write-Host "Example 1: Add a single host entry" -ForegroundColor Green
Write-Host 'Set-Hosts -Action Add -IPAddress "127.0.0.1" -Hostname "test.local"'
# Set-Hosts -Action Add -IPAddress "127.0.0.1" -Hostname "test.local"

Write-Host ""

# Example 2: Add multiple entries for local development
Write-Host "Example 2: Add local development domains" -ForegroundColor Green
Write-Host 'Set-Hosts -Action Add -IPAddress "127.0.0.1" -Hostname "myapp.local"'
Write-Host 'Set-Hosts -Action Add -IPAddress "127.0.0.1" -Hostname "api.myapp.local"'
Write-Host 'Set-Hosts -Action Add -IPAddress "127.0.0.1" -Hostname "admin.myapp.local"'
# Set-Hosts -Action Add -IPAddress "127.0.0.1" -Hostname "myapp.local"
# Set-Hosts -Action Add -IPAddress "127.0.0.1" -Hostname "api.myapp.local"
# Set-Hosts -Action Add -IPAddress "127.0.0.1" -Hostname "admin.myapp.local"

Write-Host ""

# Example 3: Block a website by redirecting to localhost
Write-Host "Example 3: Block a website (redirect to localhost)" -ForegroundColor Green
Write-Host 'Set-Hosts -Action Add -IPAddress "127.0.0.1" -Hostname "facebook.com"'
Write-Host 'Set-Hosts -Action Add -IPAddress "127.0.0.1" -Hostname "www.facebook.com"'
# Set-Hosts -Action Add -IPAddress "127.0.0.1" -Hostname "facebook.com"
# Set-Hosts -Action Add -IPAddress "127.0.0.1" -Hostname "www.facebook.com"

Write-Host ""

# Example 4: Add BebasID preset (Indonesian internet freedom)
Write-Host "Example 4: Add BebasID preset from URL" -ForegroundColor Green
Write-Host 'Set-Hosts -Action Add -PresetUrl "https://raw.githubusercontent.com/bebasid/bebasid/master/releases/hosts"'
# Set-Hosts -Action Add -PresetUrl "https://raw.githubusercontent.com/bebasid/bebasid/master/releases/hosts"

Write-Host ""

# Example 5: Add custom preset from local file
Write-Host "Example 5: Add custom preset from local file" -ForegroundColor Green
Write-Host 'Set-Hosts -Action Add -PresetFile ".\presets\custom-hosts.txt"'
# Set-Hosts -Action Add -PresetFile ".\presets\custom-hosts.txt"

Write-Host ""

# Example 6: Remove a specific hostname
Write-Host "Example 6: Remove a specific hostname" -ForegroundColor Green
Write-Host 'Set-Hosts -Action Remove -Hostname "test.local"'
# Set-Hosts -Action Remove -Hostname "test.local"

Write-Host ""

# Example 7: Remove BebasID preset
Write-Host "Example 7: Remove BebasID preset" -ForegroundColor Green
Write-Host 'Set-Hosts -Action Remove -PresetUrl "https://raw.githubusercontent.com/bebasid/bebasid/master/releases/hosts"'
# Set-Hosts -Action Remove -PresetUrl "https://raw.githubusercontent.com/bebasid/bebasid/master/releases/hosts"

Write-Host ""

# Example 8: Add entry without creating backup
Write-Host "Example 8: Add entry without backup" -ForegroundColor Green
Write-Host 'Set-Hosts -Action Add -IPAddress "192.168.1.100" -Hostname "myserver.local" -Backup:$false'
# Set-Hosts -Action Add -IPAddress "192.168.1.100" -Hostname "myserver.local" -Backup:$false

Write-Host ""

# Example 9: Point domain to specific IP (useful for testing)
Write-Host "Example 9: Point domain to specific IP" -ForegroundColor Green
Write-Host 'Set-Hosts -Action Add -IPAddress "192.168.1.50" -Hostname "staging.mycompany.com"'
# Set-Hosts -Action Add -IPAddress "192.168.1.50" -Hostname "staging.mycompany.com"

Write-Host ""
Write-Host ""

# ============================================
# PRACTICAL SCENARIOS
# ============================================

Write-Host "--- Practical Scenarios ---" -ForegroundColor Yellow
Write-Host ""

# Scenario 1: Setup local development environment
Write-Host "Scenario 1: Setup Local Development Environment" -ForegroundColor Magenta
Write-Host "# Add multiple local domains for your project"
Write-Host 'Set-Hosts -Action Add -IPAddress "127.0.0.1" -Hostname "myproject.test"'
Write-Host 'Set-Hosts -Action Add -IPAddress "127.0.0.1" -Hostname "api.myproject.test"'
Write-Host 'Set-Hosts -Action Add -IPAddress "127.0.0.1" -Hostname "cdn.myproject.test"'

Write-Host ""

# Scenario 2: Block distracting websites during work
Write-Host "Scenario 2: Block Distracting Websites" -ForegroundColor Magenta
Write-Host "# Block social media sites"
Write-Host 'Set-Hosts -Action Add -IPAddress "0.0.0.0" -Hostname "facebook.com"'
Write-Host 'Set-Hosts -Action Add -IPAddress "0.0.0.0" -Hostname "www.facebook.com"'
Write-Host 'Set-Hosts -Action Add -IPAddress "0.0.0.0" -Hostname "twitter.com"'
Write-Host 'Set-Hosts -Action Add -IPAddress "0.0.0.0" -Hostname "www.twitter.com"'

Write-Host ""

# Scenario 3: Block application internet access
Write-Host "Scenario 3: Block Application Internet Access" -ForegroundColor Magenta
Write-Host "# Prevent an application from accessing the internet"
Write-Host 'Set-FirewallRule -Path "C:\Program Files\SomeApp\app.exe" -Action Block -Direction All'

Write-Host ""

# Scenario 4: Allow server application to receive connections
Write-Host "Scenario 4: Allow Server to Receive Connections" -ForegroundColor Magenta
Write-Host "# Allow inbound connections for a local server"
Write-Host 'Set-FirewallRule -Path "C:\Servers\MyWebServer\server.exe" -Action Allow -Direction Inbound'

Write-Host ""

# Scenario 5: Clean up after testing
Write-Host "Scenario 5: Clean Up Test Entries" -ForegroundColor Magenta
Write-Host "# Remove test hosts entries"
Write-Host 'Set-Hosts -Action Remove -Hostname "test.local"'
Write-Host 'Set-Hosts -Action Remove -Hostname "myapp.local"'
Write-Host ""
Write-Host "# Remove firewall rules"
Write-Host 'Delete-FirewallRule -Path "C:\Program Files\MyApp\app.exe" -Action Block -Direction All'

Write-Host ""
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "End of Examples" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "NOTE: Uncomment the lines you want to execute!" -ForegroundColor Yellow
Write-Host "Remember: Run PowerShell as Administrator!" -ForegroundColor Red
