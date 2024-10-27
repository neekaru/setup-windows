# this program if you want to move files from one folder to another
# or copy files from one folder to another and do some pretty command

function Copy-ItemTo {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [Parameter(Mandatory=$true)]
        [string]$Destination
    )
    Copy-Item -Path $Path -Destination $Destination -Recurse -Force
}

function Invoke-CommandCustom {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Command,
        [bool]$RunAsAdmin = $false,
        [string]$Shell = "powershell" # Can be 'powershell' or 'cmd'
    )
    if ($RunAsAdmin) {
        Start-Process -FilePath $Shell -ArgumentList "/c", $Command -Verb RunAs
    } else {
        if ($Shell -eq "cmd") {
            Invoke-Expression "cmd /c $Command"
        } else {
            Invoke-Expression $Command
        }
    }
}


# example to use Execute-Command and Copy-ItemTo

# run the command
Invoke-CommandCustom -Command "Write-Host 'Hello World from Invoke-CommandCustom'" -RunAsAdmin $true

# cmd version
Invoke-CommandCustom -Command "echo Hello World from Invoke-CommandCustom" -RunAsAdmin $true -Shell "cmd"

# copy items from one folder to another
Copy-ItemTo -Path "C:\source" -Destination "C:\destination"
