<#
.SYNOPSIS
    File operations module for safe file and directory management.

.DESCRIPTION
    This module provides functions for common file operations including:
    - Copy files and directories
    - Move files and directories
    - Safe deletion to recycle bin
    - Permanent deletion with verbose output
    - ZIP file extraction
    
    All functions include error handling and support -WhatIf and -Verbose parameters.

.NOTES
    Author: Setup Windows Project
    Version: 1.0
#>

<#
.SYNOPSIS
    Copies files or directories with error handling.

.DESCRIPTION
    Safely copies files or directories from source to destination.
    Supports recursive copying for directories and force overwrite option.

.PARAMETER SourcePath
    Path to the source file or directory to copy.

.PARAMETER DestinationPath
    Path where the file or directory should be copied to.

.PARAMETER Recurse
    If specified, copies directories and all their contents recursively.

.PARAMETER Force
    If specified, overwrites existing files at the destination.

.EXAMPLE
    Copy-FileHandler -SourcePath "C:\Source\file.txt" -DestinationPath "C:\Dest\file.txt"
    Copies a single file to the destination.

.EXAMPLE
    Copy-FileHandler -SourcePath "C:\Source\Folder" -DestinationPath "C:\Dest\Folder" -Recurse
    Copies an entire directory recursively.

.EXAMPLE
    Copy-FileHandler -SourcePath "C:\Source\file.txt" -DestinationPath "C:\Dest\file.txt" -Force
    Copies a file, overwriting if it already exists.

.OUTPUTS
    Boolean. Returns $true if successful, $false otherwise.
#>
function Copy-FileHandler {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string]$SourcePath,

        [Parameter(Mandatory)]
        [string]$DestinationPath,

        [switch]$Recurse,
        [switch]$Force
    )

    try {
        # Verify source exists
        if (-not (Test-Path $SourcePath)) {
            Write-Error "Source path does not exist: $SourcePath"
            return $false
        }

        # Check if source is a directory and Recurse is not specified
        $item = Get-Item $SourcePath
        if ($item -is [System.IO.DirectoryInfo] -and -not $Recurse) {
            Write-Error "Source is a directory. Use -Recurse to copy directories."
            return $false
        }

        # Perform the copy operation with -WhatIf support
        if ($PSCmdlet.ShouldProcess($DestinationPath, "Copy from $SourcePath")) {
            if ($Force) {
                Copy-Item -Path $SourcePath -Destination $DestinationPath -Recurse:$Recurse -Force -ErrorAction Stop
            } else {
                Copy-Item -Path $SourcePath -Destination $DestinationPath -Recurse:$Recurse -ErrorAction Stop
            }

            Write-Verbose "Successfully copied: $SourcePath -> $DestinationPath"
            return $true
        }
        return $false
    } catch {
        Write-Error "Failed to copy file: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Moves files or directories with error handling.

.DESCRIPTION
    Safely moves files or directories from source to destination.
    The source will be removed after successful move.

.PARAMETER SourcePath
    Path to the source file or directory to move.

.PARAMETER DestinationPath
    Path where the file or directory should be moved to.

.PARAMETER Force
    If specified, overwrites existing files at the destination.

.EXAMPLE
    Move-FileHandler -SourcePath "C:\Source\file.txt" -DestinationPath "C:\Dest\file.txt"
    Moves a file to the destination.

.EXAMPLE
    Move-FileHandler -SourcePath "C:\Source\Folder" -DestinationPath "C:\Dest\Folder" -Force
    Moves a directory, overwriting if it exists.

.OUTPUTS
    Boolean. Returns $true if successful, $false otherwise.
#>
function Move-FileHandler {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string]$SourcePath,

        [Parameter(Mandatory)]
        [string]$DestinationPath,

        [switch]$Force
    )

    try {
        # Verify source exists
        if (-not (Test-Path $SourcePath)) {
            Write-Error "Source path does not exist: $SourcePath"
            return $false
        }

        # Perform the move operation with -WhatIf support
        if ($PSCmdlet.ShouldProcess($DestinationPath, "Move from $SourcePath")) {
            if ($Force) {
                Move-Item -Path $SourcePath -Destination $DestinationPath -Force -ErrorAction Stop
            } else {
                Move-Item -Path $SourcePath -Destination $DestinationPath -ErrorAction Stop
            }

            Write-Verbose "Successfully moved: $SourcePath -> $DestinationPath"
            return $true
        }
        return $false
    } catch {
        Write-Error "Failed to move file: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Safely deletes files or directories to the Windows Recycle Bin.

.DESCRIPTION
    Deletes files or directories by moving them to the Recycle Bin instead of
    permanent deletion. This allows recovery if needed.
    Uses Microsoft.VisualBasic.FileIO for recycle bin functionality.

.PARAMETER Path
    Path to the file or directory to delete.

.PARAMETER Force
    If specified, suppresses confirmation dialogs.

.EXAMPLE
    Remove-FileToRecycleBin -Path "C:\Temp\oldfile.txt"
    Deletes a file to the recycle bin with confirmation dialog.

.EXAMPLE
    Remove-FileToRecycleBin -Path "C:\Temp\OldFolder" -Force
    Deletes a directory to the recycle bin without confirmation.

.OUTPUTS
    Boolean. Returns $true if successful, $false otherwise.
#>
function Remove-FileToRecycleBin {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [switch]$Force
    )

    try {
        # Verify path exists
        if (-not (Test-Path $Path)) {
            Write-Error "Path does not exist: $Path"
            return $false
        }

        $item = Get-Item $Path
        $fullPath = $item.FullName

        # Perform deletion with -WhatIf support
        if ($PSCmdlet.ShouldProcess($fullPath, "Delete to Recycle Bin")) {
            # Load Visual Basic assembly for recycle bin functionality
            Add-Type -AssemblyName Microsoft.VisualBasic

            # Handle directories
            if ($item -is [System.IO.DirectoryInfo]) {
                if ($Force) {
                    # Delete directory with minimal dialogs
                    [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory(
                        $fullPath,
                        [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs,
                        [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin
                    )
                } else {
                    # Delete directory with confirmation dialogs
                    [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory(
                        $fullPath,
                        [Microsoft.VisualBasic.FileIO.UIOption]::AllDialogs,
                        [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin
                    )
                }
            } else {
                # Handle files
                if ($Force) {
                    # Delete file with minimal dialogs
                    [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile(
                        $fullPath,
                        [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs,
                        [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin
                    )
                } else {
                    # Delete file with confirmation dialogs
                    [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile(
                        $fullPath,
                        [Microsoft.VisualBasic.FileIO.UIOption]::AllDialogs,
                        [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin
                    )
                }
            }

            Write-Verbose "Successfully deleted to recycle bin: $Path"
            return $true
        }
        return $false
    } catch {
        Write-Error "Failed to delete to recycle bin: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Permanently deletes files or directories with detailed verbose output.

.DESCRIPTION
    Permanently deletes files or directories (not to recycle bin).
    Provides detailed information about the item being deleted including
    size, dates, and item count for directories.

.PARAMETER Path
    Path to the file or directory to delete permanently.

.PARAMETER Recurse
    If specified, deletes directories and all their contents recursively.

.PARAMETER Force
    If specified, deletes read-only and hidden files.

.EXAMPLE
    Remove-FileVerbose -Path "C:\Temp\file.txt" -Verbose
    Permanently deletes a file with detailed output.

.EXAMPLE
    Remove-FileVerbose -Path "C:\Temp\OldFolder" -Recurse -Force -Confirm:$false
    Permanently deletes a directory without confirmation.

.OUTPUTS
    Boolean. Returns $true if successful, $false otherwise.
#>
function Remove-FileVerbose {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
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

        Write-Verbose "Removing file/folder: $fullPath"

        if ($item -is [System.IO.DirectoryInfo]) {
            Write-Verbose "Type: Directory"
            Write-Verbose "Recurse: $Recurse"
            
            if (-not $Recurse) {
                $itemCount = @(Get-ChildItem -Path $fullPath -ErrorAction SilentlyContinue).Count
                Write-Verbose "Items in directory: $itemCount"
            }

            if ($PSCmdlet.ShouldProcess($fullPath, "Delete directory")) {
                if ($Force) {
                    Remove-Item -Path $fullPath -Recurse -Force -ErrorAction Stop
                    Write-Verbose "Verbose: Directory deleted with -Force flag"
                } else {
                    Remove-Item -Path $fullPath -Recurse -ErrorAction Stop
                    Write-Verbose "Verbose: Directory deleted"
                }
            } else {
                Write-Verbose "Deletion cancelled"
                return $false
            }
        } else {
            $fileSize = $item.Length
            Write-Verbose "Type: File"
            Write-Verbose "Size: $fileSize bytes"
            Write-Verbose "Created: $($item.CreationTime)"
            Write-Verbose "Modified: $($item.LastWriteTime)"

            if ($PSCmdlet.ShouldProcess($fullPath, "Delete file")) {
                if ($Force) {
                    Remove-Item -Path $fullPath -Force -ErrorAction Stop
                    Write-Verbose "Verbose: File deleted with -Force flag"
                } else {
                    Remove-Item -Path $fullPath -ErrorAction Stop
                    Write-Verbose "Verbose: File deleted"
                }
            } else {
                Write-Verbose "Deletion cancelled"
                return $false
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

<#
.SYNOPSIS
    Extracts ZIP archive files.

.DESCRIPTION
    Extracts the contents of a ZIP archive to a specified directory.
    Supports showing archive contents and force overwrite of existing files.
    Uses .NET System.IO.Compression for extraction.

.PARAMETER ZipPath
    Path to the ZIP file to extract.

.PARAMETER ExtractPath
    Path where the archive contents should be extracted.

.PARAMETER Force
    If specified, overwrites existing files in the extraction directory.

.PARAMETER ShowContents
    If specified, displays the list of files in the archive before extraction.

.EXAMPLE
    Expand-ZipFile -ZipPath "C:\Downloads\archive.zip" -ExtractPath "C:\Extracted"
    Extracts a ZIP file to the specified directory.

.EXAMPLE
    Expand-ZipFile -ZipPath "C:\Downloads\archive.zip" -ExtractPath "C:\Extracted" -ShowContents -Verbose
    Extracts a ZIP file and shows its contents with detailed output.

.EXAMPLE
    Expand-ZipFile -ZipPath "C:\Downloads\archive.zip" -ExtractPath "C:\Extracted" -Force
    Extracts a ZIP file, overwriting existing files.

.OUTPUTS
    Boolean. Returns $true if successful, $false otherwise.
#>
function Expand-ZipFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ZipPath,

        [Parameter(Mandatory)]
        [string]$ExtractPath,

        [switch]$Force,
        [switch]$ShowContents
    )

    try {
        # Verify ZIP file exists
        if (-not (Test-Path $ZipPath)) {
            Write-Error "Zip file not found: $ZipPath"
            return $false
        }

        # Verify file has .zip extension
        if (-not $ZipPath.EndsWith('.zip', [System.StringComparison]::InvariantCultureIgnoreCase)) {
            Write-Error "File is not a zip archive: $ZipPath"
            return $false
        }

        $zipItem = Get-Item $ZipPath
        Write-Verbose "Extracting zip archive: $($zipItem.Name)"
        Write-Verbose "Source: $ZipPath"
        Write-Verbose "Destination: $ExtractPath"

        # Create extraction directory if it doesn't exist
        if (-not (Test-Path $ExtractPath)) {
            New-Item -Path $ExtractPath -ItemType Directory -Force | Out-Null
            Write-Verbose "Created extraction directory: $ExtractPath"
        } elseif ($Force) {
            Write-Verbose "Extraction directory exists, will overwrite with -Force flag"
        } else {
            # Check if directory already has files
            $existingItems = @(Get-ChildItem -Path $ExtractPath -ErrorAction SilentlyContinue).Count
            if ($existingItems -gt 0) {
                Write-Warning "Extraction directory already contains $existingItems items"
                Write-Error "Use -Force to overwrite existing files"
                return $false
            }
        }

        # Load compression assembly
        Add-Type -AssemblyName System.IO.Compression.FileSystem

        # Open ZIP file to get information
        $zip = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
        $fileCount = $zip.Entries.Count
        Write-Verbose "Files in archive: $fileCount"

        # Show archive contents if requested
        if ($ShowContents) {
            Write-Verbose "Archive contents:"
            foreach ($entry in $zip.Entries) {
                Write-Verbose "  - $($entry.FullName) ($($entry.Length) bytes)"
            }
        }

        # Close the ZIP file before extraction
        $zip.Dispose()

        # Extract the archive
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

# Export functions
Export-ModuleMember -Function Copy-FileHandler, Move-FileHandler, Remove-FileToRecycleBin, Remove-FileVerbose, Expand-ZipFile

# Create aliases for backward compatibility and common alternative names
New-Alias -Name Copy-File -Value Copy-FileHandler
New-Alias -Name Move-File -Value Move-FileHandler
New-Alias -Name Delete-FileToRecycleBin -Value Remove-FileToRecycleBin
New-Alias -Name Delete-File -Value Remove-FileVerbose
New-Alias -Name Extract-ZipFile -Value Expand-ZipFile
New-Alias -Name Unzip-File -Value Expand-ZipFile

# Export aliases
Export-ModuleMember -Alias Copy-File, Move-File, Delete-FileToRecycleBin, Delete-File, Extract-ZipFile, Unzip-File
