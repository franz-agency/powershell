<#
.SYNOPSIS
Converts line endings of files from CRLF to LF format.

.DESCRIPTION
This script recursively searches for files with specified extensions in a given directory
and converts their line endings from Windows-style (CRLF) to Unix-style (LF).
Files in directories that start with a dot (.) are excluded from processing.

.PARAMETER Path
The directory path where the files to be converted are located. This parameter is required.

.PARAMETER Extensions
A comma-separated list of file extensions to consider for conversion (e.g., "txt,md,js,css").
Do not include the dot in the extension names. This parameter is required.

.PARAMETER DryRun
Specifies whether to perform a dry run without actually changing any files.
Valid values are "yes" (default) or "no".
When set to "yes", the script will only show which files would be converted.

.EXAMPLE
.\convert_line_ending.ps1 -Path "C:\Projects" -Extensions "txt,md,js" -DryRun "yes"
Performs a dry run showing which text, markdown, and JavaScript files would be converted.

.EXAMPLE
.\convert_line_ending.ps1 -Path "C:\Projects\Website" -Extensions "html,css,js" -DryRun "no"
Converts all HTML, CSS, and JavaScript files in the Website directory from CRLF to LF.

.NOTES
Author: System Administrator
Version: 1.1
Last Updated: $(Get-Date -Format "yyyy-MM-dd")
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, HelpMessage="Specify the directory path containing files to convert")]
    [ValidateScript({Test-Path $_ -PathType Container})]
    [string]$Path,
    
    [Parameter(Mandatory=$true, Position=1, HelpMessage="Specify file extensions to convert (comma-separated, without dots)")]
    [string]$Extensions,
    
    [Parameter(Position=2, HelpMessage="Specify 'yes' for dry run mode or 'no' to perform actual conversion")]
    [ValidateSet("yes", "no")]
    [string]$DryRun = "yes"
)

function Convert-CRLFToLF {
    <#
    .SYNOPSIS
    Converts the line endings of a file from CRLF to LF.
    
    .DESCRIPTION
    This function reads a file, checks if it contains CRLF line endings, and converts them to LF.
    In dry run mode, it only reports which files would be converted without making changes.
    
    .PARAMETER File
    The full path to the file that should be converted.
    
    .OUTPUTS
    System.String. Status messages about the conversion process.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$File
    )
    
    try {
        # Check if the file exists
        if (Test-Path -Path $File -PathType Leaf) {
            # Get the content of the file
            $content = Get-Content -Path $File -Raw -ErrorAction Stop
            
            # Check if the content is not null and contains CRLF line endings
            if ($null -ne $content -and $content.Contains("`r`n")) {
                # If DryRun is set to "no", replace the CRLF line endings with LF and save the file
                if ($DryRun -eq "no") {
                    $content = $content -replace "`r`n", "`n"
                    [System.IO.File]::WriteAllText($File, $content)
                    Write-Host "Converted: $File" -ForegroundColor Green
                    Write-Verbose "Successfully converted CRLF to LF in file: $File"
                } else {
                    Write-Host "Would convert: $File" -ForegroundColor Cyan
                    Write-Verbose "File contains CRLF line endings and would be converted: $File"
                }
            } else {
                Write-Verbose "No CRLF line endings found in: $File"
            }
        } else {
            Write-Warning "File not found: $File"
        }
    } catch {
        Write-Error "Error processing file '$File': $_"
    }
}

# Display script execution information
Write-Host "Line Endings Converter" -ForegroundColor Blue
Write-Host "==========================================" -ForegroundColor Blue
Write-Host "Path: $Path" -ForegroundColor Gray
Write-Host "Extensions: $Extensions" -ForegroundColor Gray
Write-Host "Mode: $(if ($DryRun -eq 'yes') { 'Dry Run (no changes will be made)' } else { 'Live Run (files will be modified)' })" -ForegroundColor $(if ($DryRun -eq 'yes') { 'Cyan' } else { 'Yellow' })
Write-Host "==========================================" -ForegroundColor Blue

# Split the extensions parameter into an array and trim any whitespace
$extensionArray = $Extensions -split "," | ForEach-Object { $_.Trim() }
Write-Verbose "Processing files with extensions: $($extensionArray -join ', ')"

# Get the directories to exclude (those starting with a dot)
$excludeDirs = Get-ChildItem -Path $Path -Directory | Where-Object { $_.Name.StartsWith(".") }
if ($excludeDirs) {
    Write-Verbose "Excluding directories: $($excludeDirs.FullName -join ', ')"
}

try {
    # Count for statistics
    $processedCount = 0
    $convertibleCount = 0
    
    # Get all the files in the path (recursively), excluding the directories starting with a dot
    # and only considering the files with the specified extensions
    $filesToProcess = Get-ChildItem -Path $Path -Recurse -File -ErrorAction Stop | Where-Object {
        $extensionArray -contains $_.Extension.TrimStart(".") -and
        -not ($(foreach ($dir in $excludeDirs) { $_.FullName.StartsWith($dir.FullName) }) -contains $true)
    }
    
    Write-Verbose "Found $($filesToProcess.Count) files matching the specified extensions"
    
    # Process each file
    foreach ($file in $filesToProcess) {
        $processedCount++
        $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
        
        if ($null -ne $content -and $content.Contains("`r`n")) {
            $convertibleCount++
            Convert-CRLFToLF -File $file.FullName
        } else {
            Write-Verbose "Skipping (no CRLF found): $($file.FullName)"
        }
    }
    
    # Display summary
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor Blue
    Write-Host "==========================================" -ForegroundColor Blue
    Write-Host "Files processed: $processedCount" -ForegroundColor Gray
    Write-Host "Files with CRLF: $convertibleCount" -ForegroundColor Gray
    Write-Host "$(if ($DryRun -eq 'yes') { 'Files that would be converted: ' } else { 'Files converted: ' })$convertibleCount" -ForegroundColor $(if ($DryRun -eq 'yes') { 'Cyan' } else { 'Green' })
    Write-Host "==========================================" -ForegroundColor Blue
    
} catch {
    Write-Error "Error occurred during file processing: $_"
    exit 1
}