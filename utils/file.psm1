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

        Write-Verbose "Successfully copied: $SourcePath -> $DestinationPath"
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

        Write-Verbose "Successfully moved: $SourcePath -> $DestinationPath"
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

        Write-Verbose "Successfully deleted to recycle bin: $Path"
        return $true
    } catch {
        Write-Error "Failed to delete to recycle bin: $_"
        return $false
    }
}

function Remove-FileVerbose {
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [switch]$Recurse,
        [switch]$Force,
        [switch]$Confirm
    )

    try {
        if (-not (Test-Path $Path)) {
            Write-Error "Path does not exist: $Path"
            return $false
        }

        $item = Get-Item $Path
        $fullPath = $item.FullName

        Write-Verbose "Removing file/folder: $fullPath"

        if ($item -is [System.IO.DirectoryInfo]) {
            Write-Verbose "Type: Directory"
            Write-Verbose "Recurse: $Recurse"
            
            if (-not $Recurse) {
                $itemCount = @(Get-ChildItem -Path $fullPath -ErrorAction SilentlyContinue).Count
                Write-Verbose "Items in directory: $itemCount"
            }

            if ($Confirm -and -not $Force) {
                $response = Read-Host "Are you sure you want to delete this directory? (yes/no)"
                if ($response -ne 'yes') {
                    Write-Verbose "Deletion cancelled"
                    return $false
                }
            }

            if ($Force) {
                Remove-Item -Path $fullPath -Recurse -Force -ErrorAction Stop
                Write-Verbose "Verbose: Directory deleted with -Force flag"
            } else {
                Remove-Item -Path $fullPath -Recurse -ErrorAction Stop
                Write-Verbose "Verbose: Directory deleted"
            }
        } else {
            $fileSize = $item.Length
            Write-Verbose "Type: File"
            Write-Verbose "Size: $fileSize bytes"
            Write-Verbose "Created: $($item.CreationTime)"
            Write-Verbose "Modified: $($item.LastWriteTime)"

            if ($Confirm -and -not $Force) {
                $response = Read-Host "Are you sure you want to delete this file? (yes/no)"
                if ($response -ne 'yes') {
                    Write-Verbose "Deletion cancelled"
                    return $false
                }
            }

            if ($Force) {
                Remove-Item -Path $fullPath -Force -ErrorAction Stop
                Write-Verbose "Verbose: File deleted with -Force flag"
            } else {
                Remove-Item -Path $fullPath -ErrorAction Stop
                Write-Verbose "Verbose: File deleted"
            }
        }

        if (Test-Path $fullPath) {
            Write-Error "Failed to delete: File still exists"
            return $false
        }

        Write-Verbose "Successfully deleted: $fullPath"
        return $true
    } catch {
        Write-Error "Failed to delete file: $_"
        return $false
    }
}

function Expand-ZipFile {
    param (
        [Parameter(Mandatory)]
        [string]$ZipPath,

        [Parameter(Mandatory)]
        [string]$ExtractPath,

        [switch]$Force,
        [switch]$ShowContents
    )

    try {
        if (-not (Test-Path $ZipPath)) {
            Write-Error "Zip file not found: $ZipPath"
            return $false
        }

        if (-not $ZipPath.EndsWith('.zip', [System.StringComparison]::InvariantCultureIgnoreCase)) {
            Write-Error "File is not a zip archive: $ZipPath"
            return $false
        }

        $zipItem = Get-Item $ZipPath
        Write-Verbose "Extracting zip archive: $($zipItem.Name)"
        Write-Verbose "Source: $ZipPath"
        Write-Verbose "Destination: $ExtractPath"

        if (-not (Test-Path $ExtractPath)) {
            New-Item -Path $ExtractPath -ItemType Directory -Force | Out-Null
            Write-Verbose "Created extraction directory: $ExtractPath"
        } elseif ($Force) {
            Write-Verbose "Extraction directory exists, will overwrite with -Force flag"
        } else {
            $existingItems = @(Get-ChildItem -Path $ExtractPath -ErrorAction SilentlyContinue).Count
            if ($existingItems -gt 0) {
                Write-Warning "Extraction directory already contains $existingItems items"
                Write-Error "Use -Force to overwrite existing files"
                return $false
            }
        }

        Add-Type -AssemblyName System.IO.Compression.FileSystem

        $zip = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
        $fileCount = $zip.Entries.Count
        Write-Verbose "Files in archive: $fileCount"

        if ($ShowContents) {
            Write-Verbose "Archive contents:"
            foreach ($entry in $zip.Entries) {
                Write-Verbose "  - $($entry.FullName) ($($entry.Length) bytes)"
            }
        }

        $zip.Dispose()

        [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $ExtractPath, $Force)

        Write-Verbose "Successfully extracted archive"
        $extractedItems = @(Get-ChildItem -Path $ExtractPath -Recurse -ErrorAction SilentlyContinue).Count
        Write-Verbose "Extracted items: $extractedItems"

        return $true
    } catch {
        Write-Error "Failed to extract zip file: $_"
        return $false
    }
}

Export-ModuleMember -Function Copy-FileHandler, Move-FileHandler, Remove-FileToRecycleBin, Remove-FileVerbose, Expand-ZipFile 



