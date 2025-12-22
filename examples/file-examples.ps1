<#
.SYNOPSIS
    Examples for using file.psm1 module functions.

.DESCRIPTION
    This file contains practical examples for file operations including copy, move,
    delete to recycle bin, and zip extraction.
#>

# Import the file utilities module
Import-Module ..\utils\file.psm1 -Force

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "File Utilities Examples" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================
# COPY FILE EXAMPLES
# ============================================

Write-Host "--- Copy File Examples ---" -ForegroundColor Yellow
Write-Host ""

# Example 1: Simple file copy
Write-Host "Example 1: Copy a single file" -ForegroundColor Green
Write-Host 'Copy-FileHandler -SourcePath "C:\Source\file.txt" -DestinationPath "C:\Destination\file.txt"'
# Copy-FileHandler -SourcePath "C:\Source\file.txt" -DestinationPath "C:\Destination\file.txt"

Write-Host ""

# Example 2: Copy with overwrite
Write-Host "Example 2: Copy file with overwrite" -ForegroundColor Green
Write-Host 'Copy-FileHandler -SourcePath "C:\Source\file.txt" -DestinationPath "C:\Destination\file.txt" -Force'
# Copy-FileHandler -SourcePath "C:\Source\file.txt" -DestinationPath "C:\Destination\file.txt" -Force

Write-Host ""

# Example 3: Copy entire directory
Write-Host "Example 3: Copy entire directory" -ForegroundColor Green
Write-Host 'Copy-FileHandler -SourcePath "C:\Source\MyFolder" -DestinationPath "C:\Destination\MyFolder" -Recurse'
# Copy-FileHandler -SourcePath "C:\Source\MyFolder" -DestinationPath "C:\Destination\MyFolder" -Recurse

Write-Host ""

# Example 4: Copy directory with overwrite
Write-Host "Example 4: Copy directory with overwrite" -ForegroundColor Green
Write-Host 'Copy-FileHandler -SourcePath "C:\Source\MyFolder" -DestinationPath "C:\Destination\MyFolder" -Recurse -Force'
# Copy-FileHandler -SourcePath "C:\Source\MyFolder" -DestinationPath "C:\Destination\MyFolder" -Recurse -Force

Write-Host ""

# ============================================
# MOVE FILE EXAMPLES
# ============================================

Write-Host "--- Move File Examples ---" -ForegroundColor Yellow
Write-Host ""

# Example 5: Simple file move
Write-Host "Example 5: Move a single file" -ForegroundColor Green
Write-Host 'Move-FileHandler -SourcePath "C:\Source\file.txt" -DestinationPath "C:\Destination\file.txt"'
# Move-FileHandler -SourcePath "C:\Source\file.txt" -DestinationPath "C:\Destination\file.txt"

Write-Host ""

# Example 6: Move with overwrite
Write-Host "Example 6: Move file with overwrite" -ForegroundColor Green
Write-Host 'Move-FileHandler -SourcePath "C:\Source\file.txt" -DestinationPath "C:\Destination\file.txt" -Force'
# Move-FileHandler -SourcePath "C:\Source\file.txt" -DestinationPath "C:\Destination\file.txt" -Force

Write-Host ""

# Example 7: Move directory
Write-Host "Example 7: Move entire directory" -ForegroundColor Green
Write-Host 'Move-FileHandler -SourcePath "C:\Source\MyFolder" -DestinationPath "C:\Destination\MyFolder"'
# Move-FileHandler -SourcePath "C:\Source\MyFolder" -DestinationPath "C:\Destination\MyFolder"

Write-Host ""

# ============================================
# DELETE TO RECYCLE BIN EXAMPLES
# ============================================

Write-Host "--- Delete to Recycle Bin Examples ---" -ForegroundColor Yellow
Write-Host ""

# Example 8: Delete file to recycle bin
Write-Host "Example 8: Delete file to recycle bin (safe delete)" -ForegroundColor Green
Write-Host 'Remove-FileToRecycleBin -Path "C:\Temp\oldfile.txt"'
# Remove-FileToRecycleBin -Path "C:\Temp\oldfile.txt"

Write-Host ""

# Example 9: Delete directory to recycle bin
Write-Host "Example 9: Delete directory to recycle bin" -ForegroundColor Green
Write-Host 'Remove-FileToRecycleBin -Path "C:\Temp\OldFolder"'
# Remove-FileToRecycleBin -Path "C:\Temp\OldFolder"

Write-Host ""

# Example 10: Delete without confirmation dialog
Write-Host "Example 10: Delete to recycle bin without confirmation" -ForegroundColor Green
Write-Host 'Remove-FileToRecycleBin -Path "C:\Temp\file.txt" -Force'
# Remove-FileToRecycleBin -Path "C:\Temp\file.txt" -Force

Write-Host ""

# ============================================
# PERMANENT DELETE EXAMPLES
# ============================================

Write-Host "--- Permanent Delete Examples ---" -ForegroundColor Yellow
Write-Host ""

# Example 11: Permanently delete file with verbose output
Write-Host "Example 11: Permanently delete file (with details)" -ForegroundColor Green
Write-Host 'Remove-FileVerbose -Path "C:\Temp\file.txt" -Verbose'
# Remove-FileVerbose -Path "C:\Temp\file.txt" -Verbose

Write-Host ""

# Example 12: Permanently delete directory recursively
Write-Host "Example 12: Permanently delete directory" -ForegroundColor Green
Write-Host 'Remove-FileVerbose -Path "C:\Temp\OldFolder" -Recurse -Verbose'
# Remove-FileVerbose -Path "C:\Temp\OldFolder" -Recurse -Verbose

Write-Host ""

# Example 13: Force delete without confirmation
Write-Host "Example 13: Force delete without confirmation" -ForegroundColor Green
Write-Host 'Remove-FileVerbose -Path "C:\Temp\file.txt" -Force -Confirm:$false'
# Remove-FileVerbose -Path "C:\Temp\file.txt" -Force -Confirm:$false

Write-Host ""

# ============================================
# ZIP EXTRACTION EXAMPLES
# ============================================

Write-Host "--- ZIP Extraction Examples ---" -ForegroundColor Yellow
Write-Host ""

# Example 14: Simple zip extraction
Write-Host "Example 14: Extract zip file" -ForegroundColor Green
Write-Host 'Expand-ZipFile -ZipPath "C:\Downloads\archive.zip" -ExtractPath "C:\Extracted"'
# Expand-ZipFile -ZipPath "C:\Downloads\archive.zip" -ExtractPath "C:\Extracted"

Write-Host ""

# Example 15: Extract with overwrite
Write-Host "Example 15: Extract zip with overwrite" -ForegroundColor Green
Write-Host 'Expand-ZipFile -ZipPath "C:\Downloads\archive.zip" -ExtractPath "C:\Extracted" -Force'
# Expand-ZipFile -ZipPath "C:\Downloads\archive.zip" -ExtractPath "C:\Extracted" -Force

Write-Host ""

# Example 16: Extract and show contents
Write-Host "Example 16: Extract zip and show contents" -ForegroundColor Green
Write-Host 'Expand-ZipFile -ZipPath "C:\Downloads\archive.zip" -ExtractPath "C:\Extracted" -ShowContents -Verbose'
# Expand-ZipFile -ZipPath "C:\Downloads\archive.zip" -ExtractPath "C:\Extracted" -ShowContents -Verbose

Write-Host ""

# ============================================
# PRACTICAL SCENARIOS
# ============================================

Write-Host "--- Practical Scenarios ---" -ForegroundColor Yellow
Write-Host ""

# Scenario 1: Backup files
Write-Host "Scenario 1: Backup Important Files" -ForegroundColor Magenta
Write-Host "# Create backup of important directory"
Write-Host '$source = "C:\Projects\MyApp"'
Write-Host '$backup = "D:\Backups\MyApp_$(Get-Date -Format ''yyyyMMdd'')"'
Write-Host 'Copy-FileHandler -SourcePath $source -DestinationPath $backup -Recurse -Verbose'

Write-Host ""

# Scenario 2: Clean up temp files safely
Write-Host "Scenario 2: Clean Up Temp Files Safely" -ForegroundColor Magenta
Write-Host "# Delete temporary files to recycle bin"
Write-Host '$tempFiles = Get-ChildItem -Path "C:\Temp" -Filter "*.tmp"'
Write-Host 'foreach ($file in $tempFiles) {'
Write-Host '    Remove-FileToRecycleBin -Path $file.FullName -Force'
Write-Host '    Write-Host "Deleted: $($file.Name)"'
Write-Host '}'

Write-Host ""

# Scenario 3: Extract and organize downloads
Write-Host "Scenario 3: Extract and Organize Downloads" -ForegroundColor Magenta
Write-Host "# Extract all zip files in Downloads folder"
Write-Host '$zipFiles = Get-ChildItem -Path "C:\Users\$env:USERNAME\Downloads" -Filter "*.zip"'
Write-Host 'foreach ($zip in $zipFiles) {'
Write-Host '    $extractPath = Join-Path "C:\Extracted" $zip.BaseName'
Write-Host '    Expand-ZipFile -ZipPath $zip.FullName -ExtractPath $extractPath -Verbose'
Write-Host '}'

Write-Host ""

# Scenario 4: Move old files to archive
Write-Host "Scenario 4: Archive Old Files" -ForegroundColor Magenta
Write-Host "# Move files older than 30 days to archive"
Write-Host '$cutoffDate = (Get-Date).AddDays(-30)'
Write-Host '$oldFiles = Get-ChildItem -Path "C:\WorkFiles" | Where-Object { $_.LastWriteTime -lt $cutoffDate }'
Write-Host 'foreach ($file in $oldFiles) {'
Write-Host '    $archivePath = Join-Path "C:\Archive" $file.Name'
Write-Host '    Move-FileHandler -SourcePath $file.FullName -DestinationPath $archivePath'
Write-Host '    Write-Host "Archived: $($file.Name)"'
Write-Host '}'

Write-Host ""

# Scenario 5: Safe file replacement
Write-Host "Scenario 5: Safe File Replacement with Backup" -ForegroundColor Magenta
Write-Host "# Replace file with backup of original"
Write-Host '$originalFile = "C:\Config\app.config"'
Write-Host '$newFile = "C:\Downloads\app.config"'
Write-Host '$backupFile = "C:\Config\app.config.backup"'
Write-Host ''
Write-Host '# Create backup'
Write-Host 'Copy-FileHandler -SourcePath $originalFile -DestinationPath $backupFile'
Write-Host ''
Write-Host '# Replace with new file'
Write-Host 'Move-FileHandler -SourcePath $newFile -DestinationPath $originalFile -Force'

Write-Host ""

# Scenario 6: Batch extract and cleanup
Write-Host "Scenario 6: Extract Archives and Clean Up" -ForegroundColor Magenta
Write-Host "# Extract zip files and delete archives after extraction"
Write-Host '$archives = Get-ChildItem -Path "C:\Downloads" -Filter "*.zip"'
Write-Host 'foreach ($archive in $archives) {'
Write-Host '    $extractPath = Join-Path "C:\Extracted" $archive.BaseName'
Write-Host '    $success = Expand-ZipFile -ZipPath $archive.FullName -ExtractPath $extractPath'
Write-Host '    if ($success) {'
Write-Host '        Remove-FileToRecycleBin -Path $archive.FullName -Force'
Write-Host '        Write-Host "Extracted and removed: $($archive.Name)"'
Write-Host '    }'
Write-Host '}'

Write-Host ""

# Scenario 7: Organize files by extension
Write-Host "Scenario 7: Organize Files by Extension" -ForegroundColor Magenta
Write-Host "# Move files to folders based on extension"
Write-Host '$sourceFolder = "C:\Downloads"'
Write-Host '$files = Get-ChildItem -Path $sourceFolder -File'
Write-Host 'foreach ($file in $files) {'
Write-Host '    $extension = $file.Extension.TrimStart(".")'
Write-Host '    if ($extension) {'
Write-Host '        $destFolder = Join-Path $sourceFolder $extension.ToUpper()'
Write-Host '        if (-not (Test-Path $destFolder)) {'
Write-Host '            New-Item -Path $destFolder -ItemType Directory | Out-Null'
Write-Host '        }'
Write-Host '        $destPath = Join-Path $destFolder $file.Name'
Write-Host '        Move-FileHandler -SourcePath $file.FullName -DestinationPath $destPath'
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
Write-Host "WARNING: Be careful with delete operations!" -ForegroundColor Red
