# this is for handler copy file, move file, delete file to recycle bin

function Copy-FileHandler {
    param (
        [Parameter(Mandatory)]
        [string]$SourcePath,

        [Parameter(Mandatory)]
        [string]$DestinationPath,

        [switch]$Recurse,
        [switch]$Force
    )

    try {
        if (-not (Test-Path $SourcePath)) {
            Write-Error "Source path does not exist: $SourcePath"
            return $false
        }

        $item = Get-Item $SourcePath
        if ($item -is [System.IO.DirectoryInfo] -and -not $Recurse) {
            Write-Error "Source is a directory. Use -Recurse to copy directories."
            return $false
        }

        if ($Force) {
            Copy-Item -Path $SourcePath -Destination $DestinationPath -Recurse:$Recurse -Force -ErrorAction Stop
        } else {
            Copy-Item -Path $SourcePath -Destination $DestinationPath -Recurse:$Recurse -ErrorAction Stop
        }

        Write-Host "Successfully copied: $SourcePath -> $DestinationPath"
        return $true
    } catch {
        Write-Error "Failed to copy file: $_"
        return $false
    }
}

function Move-FileHandler {
    param (
        [Parameter(Mandatory)]
        [string]$SourcePath,

        [Parameter(Mandatory)]
        [string]$DestinationPath,

        [switch]$Force
    )

    try {
        if (-not (Test-Path $SourcePath)) {
            Write-Error "Source path does not exist: $SourcePath"
            return $false
        }

        if ($Force) {
            Move-Item -Path $SourcePath -Destination $DestinationPath -Force -ErrorAction Stop
        } else {
            Move-Item -Path $SourcePath -Destination $DestinationPath -ErrorAction Stop
        }

        Write-Host "Successfully moved: $SourcePath -> $DestinationPath"
        return $true
    } catch {
        Write-Error "Failed to move file: $_"
        return $false
    }
}

function Remove-FileToRecycleBin {
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [switch]$Recurse,
        [switch]$Force
    )

    try {
        if (-not (Test-Path $Path)) {
            Write-Error "Path does not exist: $Path"
            return $false
        }

        $item = Get-Item $Path
        $fullPath = $item.FullName

        Add-Type -AssemblyName Microsoft.VisualBasic

        if ($item -is [System.IO.DirectoryInfo]) {
            if ($Force) {
                [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory(
                    $fullPath,
                    [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs,
                    [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin
                )
            } else {
                [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory(
                    $fullPath,
                    [Microsoft.VisualBasic.FileIO.UIOption]::AllDialogs,
                    [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin
                )
            }
        } else {
            if ($Force) {
                [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile(
                    $fullPath,
                    [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs,
                    [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin
                )
            } else {
                [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile(
                    $fullPath,
                    [Microsoft.VisualBasic.FileIO.UIOption]::AllDialogs,
                    [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin
                )
            }
        }

        Write-Host "Successfully deleted to recycle bin: $Path"
        return $true
    } catch {
        Write-Error "Failed to delete to recycle bin: $_"
        return $false
    }
}

Export-ModuleMember -Function Copy-FileHandler, Move-FileHandler, Remove-FileToRecycleBin 


