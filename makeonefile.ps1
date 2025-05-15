<#
.SYNOPSIS
    Combines the content of multiple files into a single output file.

.DESCRIPTION
    This script combines the content of all files from a specified directory and its subdirectories into a single output file.
    Each file's content is preceded by a separator showing its relative path. The separator format is "======= path/to/file =======".
    
    This is useful for code reviews, documentation, or when you need to share multiple files as a single document.
    
    By default, the script excludes:
    - Directories that start with a dot (.) 
    - Files that start with a dot (.)
    - Binary files (images, executables, PDF, etc.)
    - Standard directories: 'vendor/', 'node_modules/', 'build/', 'dist/' and 'cache/'
    
    Note: XML-based formats like .docx, .xlsx, .pptx, and .svg are NOT excluded by default.

.PARAMETER SourceDirectory
    The path to the directory containing the files to be combined. All files in this directory and its subdirectories will be processed.
    This parameter accepts both absolute and relative paths. If a relative path is provided, it will be resolved based on the current working directory.

.PARAMETER OutputFile
    The path where the combined output file will be created.
    This parameter accepts both absolute and relative paths. If a relative path is provided, it will be resolved based on the current working directory.

.PARAMETER Force
    If specified, automatically overwrites the output file if it already exists without prompting for confirmation.
    If not specified and the file exists, the user will be prompted to confirm overwriting.

.PARAMETER AddTimestamp
    If specified, adds a timestamp to the output filename in the format "_yyyyMMdd_HHmmss".
    For example, if OutputFile is "output.txt", the actual file created might be "output_20250515_102030.txt".

.PARAMETER AdditionalExcludes
    An array of additional directory paths to exclude from processing. These paths are relative to the source directory.
    For example, to exclude 'build' and 'dist' directories, use: -AdditionalExcludes @('build', 'dist')

.PARAMETER IncludeDotFiles
    If specified, includes files that start with a dot (e.g., .gitignore, .env) in the output.
    By default, such files are excluded.

.PARAMETER IncludeBinaryFiles
    If specified, includes binary files (images, executables, etc.) in the output.
    By default, binary files are excluded to prevent corrupted output and to keep the output file readable.

.EXAMPLE
    .\makeonefile.ps1 -SourceDirectory "C:\Projects\MyCode" -OutputFile "C:\Temp\combined_code.txt"
    
    Combines all files from C:\Projects\MyCode and its subdirectories into C:\Temp\combined_code.txt,
    excluding directories starting with a dot, vendor/, and node_modules/.
    If the output file already exists, the user will be prompted for confirmation.

.EXAMPLE
    .\makeonefile.ps1 -SourceDirectory ".\src" -OutputFile "combined_src.txt" -Force
    
    Combines all files from the src directory and automatically overwrites the output file if it exists.

.EXAMPLE
    .\makeonefile.ps1 -SourceDirectory ".\src" -OutputFile "combined_src.txt" -AddTimestamp
    
    Combines all files and creates an output file with a timestamp, e.g., "combined_src_20250515_102030.txt".

.EXAMPLE
    $srcDir = "D:\Projects\WebApp"
    $outputPath = "D:\Documentation\WebApp_Full_Source.txt"
    .\makeonefile.ps1 -SourceDirectory $srcDir -OutputFile $outputPath -AdditionalExcludes @('temp') -IncludeDotFiles
    
    Combines all files including dot files (like .gitignore) but excludes 'temp' directory in addition to the default exclusions.

.EXAMPLE
    .\makeonefile.ps1 -SourceDirectory "D:\Projects\Media" -OutputFile "media_report.txt" -IncludeBinaryFiles
    
    Combines all files including binary files (which are excluded by default). Note that including binary files
    may result in unreadable content in the output file for certain file types.

.NOTES
    Author: Franz und Franz
    Date: May 15, 2025
    Version: 1.5.1
    
    The script processes all file types found in the directory structure. No filtering by file extension is performed.
    Very large directories with many files may take some time to process and could create a large output file.
    
    If you encounter permission issues, make sure you have read access to all files in the source directory
    and write access to the location where the output file will be created.

.LINK
    Get-ChildItem: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-childitem
    Add-Content: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/add-content
#>

param (
    # Path to the directory to be searched
    [Parameter(Mandatory=$true)]
    [string]$SourceDirectory,
    
    # Path to the output file
    [Parameter(Mandatory=$true)]
    [string]$OutputFile,
    
    # Force overwrite of output file without prompting
    [Parameter(Mandatory=$false)]
    [switch]$Force,
    
    # Add timestamp to output filename
    [Parameter(Mandatory=$false)]
    [switch]$AddTimestamp,
    
    # Additional directories to exclude (relative paths)
    [Parameter(Mandatory=$false)]
    [string[]]$AdditionalExcludes = @(),
    
    # Include files that start with a dot
    [Parameter(Mandatory=$false)]
    [switch]$IncludeDotFiles,
    
    # Include binary files (images, executables, etc.)
    [Parameter(Mandatory=$false)]
    [switch]$IncludeBinaryFiles
)

# Process the output file path
$finalOutputFile = $OutputFile

# Add timestamp to filename if requested
if ($AddTimestamp) {
    $timestamp = Get-Date -Format "_yyyyMMdd_HHmmss"
    $fileInfo = [System.IO.FileInfo]$OutputFile
    $finalOutputFile = Join-Path $fileInfo.DirectoryName ($fileInfo.BaseName + $timestamp + $fileInfo.Extension)
    Write-Host "Adding timestamp to output filename: $finalOutputFile"
}

# Check if the output file already exists
if (Test-Path $finalOutputFile) {
    if ($Force) {
        Write-Host "Output file already exists. Overwriting due to -Force parameter..."
        Remove-Item $finalOutputFile
    } else {
        $confirmation = Read-Host "Output file '$finalOutputFile' already exists. Do you want to overwrite it? (Y/N)"
        if ($confirmation -ne 'Y' -and $confirmation -ne 'y') {
            Write-Host "Operation cancelled by user."
            exit
        }
        Remove-Item $finalOutputFile
    }
}

# Define default excluded directories
$defaultExcludes = @(
    'vendor',
    'node_modules',
    'build',
    'dist',
    'cache'
)

# Combine default excludes with additional excludes
$allExcludes = $defaultExcludes + $AdditionalExcludes

# Define binary file extensions to exclude
$binaryExtensions = @(
    # Images
    '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.ico', '.webp',
    # Audio
    '.mp3', '.wav', '.ogg', '.flac', '.aac', '.wma',
    # Video
    '.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm',
    # Executables and binaries
    '.exe', '.dll', '.so', '.dylib', '.bin', '.dat',
    # Archives
    '.zip', '.rar', '.7z', '.tar', '.gz', '.bz2',
    # Binary documents (non-XML based)
    '.pdf', '.doc', '.ppt',
    # Databases
    '.db', '.sqlite', '.mdb',
    # Fonts and web assets
    '.ttf', '.otf', '.woff', '.woff2',
    # Proprietary design formats
    '.psd', '.ai', '.xd'
    # Note: .docx, .xlsx, .pptx are excluded as they are XML-based formats
    # .svg is also excluded as it is XML-based
)

# Initialize empty array for files
$files = @()

Write-Host "Scanning files in $SourceDirectory..." -ForegroundColor Green

# Display exclusion information
$excludeInfo = "Excluded: "
$excludeInfo += "dot-directories (.*), "
if (-not $IncludeDotFiles) { $excludeInfo += "dot-files (.file), " }
if (-not $IncludeBinaryFiles) { $excludeInfo += "binary files, " }
$excludeInfo += "$($allExcludes -join ', ')"
Write-Host $excludeInfo -ForegroundColor Yellow

# Display inclusion information
if ($IncludeDotFiles) { Write-Host "Dot files (.file) will be INCLUDED" -ForegroundColor Cyan }
if ($IncludeBinaryFiles) { Write-Host "Binary files will be INCLUDED" -ForegroundColor Cyan }

# Get all files while excluding specified directories
$allItems = Get-ChildItem -Path $SourceDirectory -Recurse -Force

# Filter to include only files that are not in excluded directories
foreach ($item in $allItems) {
    if ($item.PSIsContainer) { continue } # Skip directories
    
    $relativePath = $item.FullName.Substring($(Resolve-Path $SourceDirectory).Path.TrimEnd('\').Length + 1)
    $pathParts = $relativePath.Split([IO.Path]::DirectorySeparatorChar)
    
    $shouldExclude = $false
    
    # Check if any part of the path starts with a dot (for directories)
    foreach ($part in $pathParts) {
        if ($part.StartsWith('.') -and $part.Length -gt 1) {
            $shouldExclude = $true
            break
        }
    }
    
    # Check if the file itself starts with a dot (unless IncludeDotFiles is specified)
    if (-not $shouldExclude -and -not $IncludeDotFiles) {
        $fileName = [System.IO.Path]::GetFileName($item.Name)
        if ($fileName.StartsWith('.')) {
            $shouldExclude = $true
        }
    }
    
    # Check if the file is a binary file (unless IncludeBinaryFiles is specified)
    if (-not $shouldExclude -and -not $IncludeBinaryFiles) {
        $extension = [System.IO.Path]::GetExtension($item.Name).ToLower()
        if ($binaryExtensions -contains $extension) {
            $shouldExclude = $true
        }
    }
    
    # Check if any part of the path matches an excluded directory
    if (-not $shouldExclude) {
        foreach ($exclude in $allExcludes) {
            if ($pathParts -contains $exclude) {
                $shouldExclude = $true
                break
            }
        }
    }
    
    if (-not $shouldExclude) {
        $files += $item
    }
}

# Process each file
$totalFiles = $files.Count
Write-Host "Processing $totalFiles files..." -ForegroundColor Green

foreach ($file in $files) {
    # Determine the relative path to the file
    # Ensure proper path handling regardless of whether SourceDirectory ends with a backslash
    $normalizedSourcePath = $(Resolve-Path $SourceDirectory).Path.TrimEnd('\') + '\'
    $relativePath = $file.FullName.Substring($normalizedSourcePath.Length)
    
    # Write separator line with relative path and filename
    Add-Content -Path $finalOutputFile -Value ("======= " + $relativePath + " =======")
    # Add an empty line
    Add-Content -Path $finalOutputFile -Value ""
    # Try to read the content of the file and add it to the output file
    try {
        Get-Content -Path $file.FullName -ErrorAction Stop | Add-Content -Path $finalOutputFile
    } catch {
        # If a file can't be read, add a note about it
        Add-Content -Path $finalOutputFile -Value "[UNABLE TO READ FILE: $($_.Exception.Message)]"
    }
    # Add an empty line
    Add-Content -Path $finalOutputFile -Value ""
}

Write-Host "All files have been combined in $finalOutputFile." -ForegroundColor Green
Write-Host "Total files processed: $totalFiles" -ForegroundColor Cyan
