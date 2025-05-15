<#
.SYNOPSIS
    Combines the content of multiple text files into a single output file, with metadata.

.DESCRIPTION
    This script combines the content of text files from a specified directory and its subdirectories 
    into a single output file. Each file's content is preceded by a separator showing metadata 
    such as the file path, modification date, size, and type.
    
    This is useful for code reviews, creating documentation bundles, or when you need to share 
    multiple source files as a single document.
    
    By default, the script excludes:
    - Directories whose names start with a dot (.) (e.g., .git, .vscode)
    - Files whose names start with a dot (.) (e.g., .gitignore, .env)
    - Binary files based on a predefined list of extensions (images, executables, PDF, archives, etc.)
    - Standard project directories: 'vendor/', 'node_modules/', 'build/', 'dist/', and 'cache/' (case-insensitive, anywhere in the path)
    
    Note: XML-based office formats (.docx, .xlsx, .pptx) and .svg are generally NOT considered binary 
    by the default exclusion list and may be included if not otherwise excluded.

.PARAMETER SourceDirectory
    The path to the directory containing the files to be combined. All eligible files in this 
    directory and its subdirectories will be processed.
    This parameter accepts both absolute and relative paths.

.PARAMETER OutputFile
    The path where the combined output file will be created.
    This parameter accepts both absolute and relative paths.

.PARAMETER Force
    If specified, automatically overwrites the output file if it already exists without prompting.
    If not specified and the file exists, the user will be prompted to confirm overwriting.

.PARAMETER AddTimestamp
    If specified, adds a timestamp to the output filename in the format "_yyyyMMdd_HHmmss".
    For example, if OutputFile is "output.txt", the actual file created might be "output_20231027_102030.txt".

.PARAMETER AdditionalExcludes
    An array of additional directory *names* to exclude from processing (e.g., 'temp', 'logs'). 
    These names are matched case-insensitively. If a directory anywhere in the path matches one of these names, 
    files within it will be excluded.
    Example: -AdditionalExcludes @('obj', 'Debug')

.PARAMETER IncludeDotFiles
    If specified, includes files that start with a dot (e.g., .gitignore, .env) in the output.
    By default, such files are excluded. Dot directories (e.g. .git) are always excluded.

.PARAMETER IncludeBinaryFiles
    If specified, attempts to include files identified as binary by their extension.
    By default, binary files are excluded. Including binary files may result in unreadable or 
    corrupted-looking content in the output text file and can significantly increase output file size.

.PARAMETER SeparatorStyle
    Controls the format of the separator between files in the output. Available options:
    - 'Standard': Simple separator with just the path ("======= path/to/file =======")
    - 'Detailed': Enhanced separator with file path, date, size, and type (Default)
    - 'Markdown': Markdown-style separator with code block hints for use in documentation.

.EXAMPLE
    .\makeonefile.ps1 -SourceDirectory "C:\Projects\MyCode" -OutputFile "C:\Temp\combined_code.txt"
    
    Combines text files from C:\Projects\MyCode into C:\Temp\combined_code.txt.
    Default exclusions apply. Prompts if output file exists.

.EXAMPLE
    .\makeonefile.ps1 -SourceDirectory ".\src" -OutputFile "combined_src.txt" -Force
    
    Combines files from the 'src' subdirectory and overwrites 'combined_src.txt' if it exists.

.EXAMPLE
    .\makeonefile.ps1 -SourceDirectory ".\src" -OutputFile "combined_src.txt" -AddTimestamp
    
    Combines files and creates an output file with a timestamp, e.g., "combined_src_20231027_102030.txt".

.EXAMPLE
    $srcDir = "D:\Projects\WebApp"
    $outputPath = "D:\Documentation\WebApp_Full_Source.txt"
    .\makeonefile.ps1 -SourceDirectory $srcDir -OutputFile $outputPath -AdditionalExcludes @('temp_files', 'backup') -IncludeDotFiles
    
    Combines files, including dot files (like .gitignore). Excludes 'temp_files' and 'backup' 
    directories in addition to default exclusions.

.EXAMPLE
    .\makeonefile.ps1 -SourceDirectory "D:\Projects\Media" -OutputFile "media_report.txt" -IncludeBinaryFiles
    
    Attempts to combine all files including those with binary extensions. Use with caution.

.EXAMPLE
    .\makeonefile.ps1 -SourceDirectory "D:\Projects\WebApp" -OutputFile "code_review.md" -SeparatorStyle Markdown
    
    Combines files using Markdown formatting for separators, suitable for platforms like GitHub.

.NOTES
    Author: Franz und Franz (Reviewed and enhanced by AI)
    Date: 2023-10-27 (Original: May 15, 2025)
    Version: 1.7.0
    
    The script primarily targets text-based files. While -IncludeBinaryFiles exists, its use
    can lead to very large and potentially unreadable output files.
    
    Performance: For very large numbers of files or extremely large individual files, processing 
    can take time. The script reads each approved file's content fully into memory before writing it.
    
    Permissions: Requires read access to source files/directories and write access to the output location.
    Error Handling: The script will attempt to continue if individual files cannot be read, noting errors in the output.
    Critical errors (like invalid source/output paths) will terminate the script.

.LINK
    Get-ChildItem: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-childitem
    Add-Content: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/add-content
    Resolve-Path: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/resolve-path
    about_Comment_Based_Help: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help
#>
[CmdletBinding()] # Adds support for common parameters like -Verbose, -Debug, -ErrorAction
param (
    [Parameter(Mandatory=$true, HelpMessage="Path to the directory to be searched.")]
    [string]$SourceDirectory,
    
    [Parameter(Mandatory=$true, HelpMessage="Path to the output file.")]
    [string]$OutputFile,
    
    [Parameter(Mandatory=$false, HelpMessage="Force overwrite of output file without prompting.")]
    [switch]$Force,
    
    [Parameter(Mandatory=$false, HelpMessage="Add timestamp to output filename.")]
    [switch]$AddTimestamp,
    
    [Parameter(Mandatory=$false, HelpMessage="Additional directory names to exclude (e.g., 'obj', 'debug'). Case-insensitive.")]
    [string[]]$AdditionalExcludes = @(),
    
    [Parameter(Mandatory=$false, HelpMessage="Include files that start with a dot (e.g., .gitignore). Dot directories are always excluded.")]
    [switch]$IncludeDotFiles,
    
    [Parameter(Mandatory=$false, HelpMessage="Attempt to include binary files (images, executables, etc.). May result in unreadable content.")]
    [switch]$IncludeBinaryFiles,
    
    [Parameter(Mandatory=$false, HelpMessage="Separator style for file content.")]
    [ValidateSet('Standard', 'Detailed', 'Markdown')]
    [string]$SeparatorStyle = 'Detailed'
)

# --- Script Setup ---
$ErrorActionPreference = 'Stop' # Exit on script-terminating errors (does not affect Read-Host, Test-Path etc. directly)

# --- Path Resolution and Validation ---
try {
    $resolvedSourceDirectory = (Resolve-Path -LiteralPath $SourceDirectory -ErrorAction Stop).ProviderPath
    if (-not (Test-Path -LiteralPath $resolvedSourceDirectory -PathType Container)) {
        Write-Error "Source directory '$resolvedSourceDirectory' is not a valid directory."
        exit 1
    }
} catch {
    Write-Error "Source directory '$SourceDirectory' not found or inaccessible: $($_.Exception.Message)"
    exit 1
}

# Resolve OutputFile to an absolute path. New-Object FileInfo handles relative/absolute paths and normalizes.
$outputFileObject = New-Object System.IO.FileInfo $OutputFile 
$currentFinalOutputFile = $outputFileObject.FullName

if ($AddTimestamp.IsPresent) {
    $timestamp = Get-Date -Format "_yyyyMMdd_HHmmss"
    # $outputFileObject.DirectoryName is the absolute path to the directory
    # $outputFileObject.Name is just the file name part
    $dirName = $outputFileObject.DirectoryName 
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($outputFileObject.Name)
    $extension = $outputFileObject.Extension # Includes the dot, e.g. ".txt"
    
    $currentFinalOutputFile = Join-Path -Path $dirName -ChildPath ($baseName + $timestamp + $extension)
    Write-Verbose "Adding timestamp to output filename. Final path will be: $currentFinalOutputFile"
}

# --- Output File Handling ---
# Check if output file exists (as a file, not directory)
if (Test-Path -LiteralPath $currentFinalOutputFile -PathType Leaf) {
    if ($Force.IsPresent) {
        Write-Warning "Output file '$currentFinalOutputFile' already exists. Overwriting due to -Force parameter."
        Remove-Item -LiteralPath $currentFinalOutputFile -Force
    } else {
        # Temporarily change ErrorActionPreference for Read-Host, as 'Stop' can affect Ctrl+C behavior
        $oldErrorActionPref = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            $confirmation = Read-Host "Output file '$currentFinalOutputFile' already exists. Do you want to overwrite it? (Y/N)"
        } finally {
            $ErrorActionPreference = $oldErrorActionPref
        }
        
        if ($confirmation -notmatch '^[Yy]$') {
            Write-Warning "Operation cancelled by user."
            exit 0 # Successful exit, user choice
        }
        Write-Verbose "Overwriting existing output file '$currentFinalOutputFile'."
        Remove-Item -LiteralPath $currentFinalOutputFile -Force
    }
}

# Ensure output directory exists
$outputDir = [System.IO.Path]::GetDirectoryName($currentFinalOutputFile)
if (-not ([string]::IsNullOrEmpty($outputDir)) -and (-not (Test-Path -LiteralPath $outputDir -PathType Container))) {
    Write-Verbose "Creating output directory: $outputDir"
    New-Item -Path $outputDir -ItemType Directory -Force:$true | Out-Null # -Force ensures no error if it exists or needs to create parent
}

# --- Exclusion Definitions ---
$defaultExcludedDirNames = @( # Directory Names, not paths
    'vendor',
    'node_modules',
    'build',
    'dist',
    'cache'
)
# Combine, lowercase, and unique-fy all directory names to exclude
$allExcludedDirNames = ($defaultExcludedDirNames + $AdditionalExcludes) | ForEach-Object { $_.ToLowerInvariant() } | Get-Unique

# Expanded list of common binary file extensions
$binaryFileExtensions = @(
    # Images
    '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.tif', '.ico', '.webp', '.svgz', # Note: .svg is XML, not here
    # Audio
    '.mp3', '.wav', '.ogg', '.flac', '.aac', '.wma', '.m4a',
    # Video
    '.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm', '.mpeg', '.mpg',
    # Executables and compiled code
    '.exe', '.dll', '.so', '.dylib', '.bin', '.msi', '.pdb', '.lib', '.o', '.obj', '.pyc', '.pyo', '.class',
    # Archives
    '.zip', '.rar', '.7z', '.tar', '.gz', '.bz2', '.xz', '.jar', '.war', '.ear', '.cab',
    # Binary documents (non-XML based Office, PDF)
    '.pdf', '.doc', '.ppt', # .docx, .xlsx, .pptx are XML-based, generally not here unless specifically added
    # Databases & Data Files
    '.db', '.sqlite', '.mdb', '.accdb', '.dbf', # .dat is generic, can be text or binary
    # Fonts
    '.ttf', '.otf', '.woff', '.woff2', '.eot',
    # Proprietary design formats
    '.psd', '.ai', '.indd', '.xd', '.fig',
    # Virtualization & Disk Images
    '.iso', '.img', '.vhd', '.vhdx', '.vmdk',
    # Other common binary types
    '.bak', '.tmp', '.lock', '.swo', '.swp' # Often binary or not intended for inclusion
)

# --- File Scanning and Filtering ---
Write-Host "Scanning files in '$resolvedSourceDirectory'..." -ForegroundColor Green

$exclusionSummary = "Exclusion criteria applied: "
$exclusionSummaryParts = @()
$exclusionSummaryParts += "Directories starting with `'.`' (e.g., .git)"
if (-not $IncludeDotFiles.IsPresent) { $exclusionSummaryParts += "Files starting with `'.`' (e.g., .gitignore)" }
if (-not $IncludeBinaryFiles.IsPresent) { $exclusionSummaryParts += "Files with binary extensions (e.g., .png, .exe)" }
if ($allExcludedDirNames.Count -gt 0) {
    $exclusionSummaryParts += "Directory names: $($allExcludedDirNames -join ', ')"
}
Write-Verbose ($exclusionSummary + ($exclusionSummaryParts -join "; "))


if ($IncludeDotFiles.IsPresent) { Write-Verbose "Dot files (e.g., .gitignore) will be INCLUDED." }
if ($IncludeBinaryFiles.IsPresent) { Write-Verbose "Files with binary extensions will be INCLUDED (content may be unreadable)." }
Write-Verbose "Using separator style: $SeparatorStyle"

# Get all files, then filter. -ErrorAction SilentlyContinue for Get-ChildItem to skip inaccessible subfolders.
$filesToProcess = Get-ChildItem -Path $resolvedSourceDirectory -Recurse -Force -File -ErrorAction SilentlyContinue | ForEach-Object {
    $fileInfo = $_
    $shouldExclude = $false

    # 1. Calculate relative path (relative to $resolvedSourceDirectory)
    $sourcePathWithSeparator = $resolvedSourceDirectory.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    $currentRelativePath = $fileInfo.FullName
    if ($currentRelativePath.StartsWith($sourcePathWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)) {
        $currentRelativePath = $currentRelativePath.Substring($sourcePathWithSeparator.Length)
    } else { 
        # This case should ideally not be hit if Get-ChildItem works as expected from $resolvedSourceDirectory
        # Fallback to just the name if full path doesn't start with source (e.g. symlink to outside)
        Write-Warning "File '$($fileInfo.FullName)' seems to be outside the source directory structure. Using filename as relative path."
        $currentRelativePath = $fileInfo.Name 
    }

    $pathSegments = $currentRelativePath.Split([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $directorySegments = $pathSegments | Select-Object -SkipLast 1 # Path components excluding filename

    # 2. Exclude if in a dot-directory (e.g., .git/config)
    # This rule applies regardless of $IncludeDotFiles, as it's about directories.
    foreach ($segment in $directorySegments) {
        if ($segment.StartsWith('.')) {
            $shouldExclude = $true
            Write-Verbose "Excluding (in dot-directory '$segment'): $($fileInfo.FullName)"
            break
        }
    }

    # 3. Exclude dot-files if -IncludeDotFiles is not specified
    if (-not $shouldExclude -and -not $IncludeDotFiles.IsPresent) {
        if ($fileInfo.Name.StartsWith('.')) {
            $shouldExclude = $true
            Write-Verbose "Excluding (dot-file): $($fileInfo.FullName)"
        }
    }
    
    # 4. Exclude binary files if -IncludeBinaryFiles is not specified
    if (-not $shouldExclude -and -not $IncludeBinaryFiles.IsPresent) {
        $extension = $fileInfo.Extension.ToLowerInvariant() # .Extension includes the dot, e.g. ".jpg"
        if ($binaryFileExtensions -contains $extension) {
            $shouldExclude = $true
            Write-Verbose "Excluding (binary extension '$extension'): $($fileInfo.FullName)"
        }
    }

    # 5. Exclude if in a standard excluded directory (e.g., node_modules/somefile.js)
    if (-not $shouldExclude -and $allExcludedDirNames.Count -gt 0) {
        $lowerDirectorySegments = $directorySegments | ForEach-Object { $_.ToLowerInvariant() }
        foreach ($excludedDirName_Lower in $allExcludedDirNames) { # $excludedDirName_Lower is already lowercase
            if ($lowerDirectorySegments -contains $excludedDirName_Lower) {
                $shouldExclude = $true
                Write-Verbose "Excluding (in standard excluded directory '$excludedDirName_Lower'): $($fileInfo.FullName)"
                break
            }
        }
    }

    if (-not $shouldExclude) {
        [PSCustomObject]@{
            FileInfo     = $fileInfo
            RelativePath = $currentRelativePath # Store the calculated relative path
        }
    }
}

if ($null -eq $filesToProcess -or $filesToProcess.Count -eq 0) {
    Write-Warning "No files found matching the criteria in '$resolvedSourceDirectory'."
    # Create an empty output file as per original behavior rather than exiting
    Set-Content -Path $currentFinalOutputFile -Value "" -NoNewline -ErrorAction SilentlyContinue
    Write-Host "Empty output file created at '$currentFinalOutputFile'."
    exit 0
}

$totalFiles = $filesToProcess.Count
Write-Host "Processing $totalFiles files for inclusion..." -ForegroundColor Green

# --- Separator Functions ---
function Get-FileSeparator {
    param (
        [Parameter(Mandatory=$true)]
        [System.IO.FileInfo]$LocalFileInfo, 
        [Parameter(Mandatory=$true)]
        [string]$LocalRelativePath, 
        [Parameter(Mandatory=$true)]
        [string]$Style
    )
    
    switch ($Style) {
        'Standard' {
            return "======= $LocalRelativePath ======="
        }
        'Detailed' {
            $modDate = $LocalFileInfo.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
            $fileSizeInBytes = $LocalFileInfo.Length
            $fileSizeFormatted = ""
            if ($fileSizeInBytes -lt 1024) {
                $fileSizeFormatted = "$fileSizeInBytes Bytes"
            } elseif ($fileSizeInBytes -lt (1024*1024)) { # Less than 1 MB
                $fileSizeFormatted = "{0:N2} KB" -f ($fileSizeInBytes / 1KB)
            } else { # 1 MB or more
                $fileSizeFormatted = "{0:N2} MB" -f ($fileSizeInBytes / 1MB)
            }
            
            $fileExt = if ($LocalFileInfo.Extension) { $LocalFileInfo.Extension.ToLowerInvariant() } else { "[no extension]" }
            
            $separator = @(
                "========================================================================================",
                "== FILE: $LocalRelativePath",
                "== DATE: $modDate | SIZE: $fileSizeFormatted | TYPE: $fileExt",
                "========================================================================================"
            )
            return $separator -join [System.Environment]::NewLine
        }
        'Markdown' {
            $modDate = $LocalFileInfo.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
            $fileSizeInBytes = $LocalFileInfo.Length
            $fileSizeFormatted = ""
            if ($fileSizeInBytes -lt 1024) {
                $fileSizeFormatted = "$fileSizeInBytes Bytes"
            } elseif ($fileSizeInBytes -lt (1024*1024)) {
                $fileSizeFormatted = "{0:N2} KB" -f ($fileSizeInBytes / 1KB)
            } else {
                $fileSizeFormatted = "{0:N2} MB" -f ($fileSizeInBytes / 1MB)
            }
            $mdExtension = $LocalFileInfo.Extension.TrimStart('.') # For ```language hint
            
            $separator = @(
                "## $LocalRelativePath", 
                "**Date Modified:** $modDate | **Size:** $fileSizeFormatted | **Type:** $($LocalFileInfo.Extension)",
                "", 
                "```$mdExtension" 
             )
            return $separator -join [System.Environment]::NewLine
        }
        default { # Should not happen due to ValidateSet
            return "--- $LocalRelativePath ---"
        }
    }
}

function Get-ClosingSeparator {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Style
    )
    # Returns the appropriate closing separator based on the chosen style.
    # For Markdown we simply close the fenced code block. For other styles
    # we return $null so that no extra line is added.
    if ($Style -eq 'Markdown') {
        return "```"
    }
    return $null # Do not add a closing separator for non-Markdown styles
}

# --- File Content Aggregation ---
$fileCounter = 0
foreach ($processedEntry in $filesToProcess) {
    $fileCounter++
    $currentFileToProcess = $processedEntry.FileInfo # This is the FileInfo object
    $currentRelativePathForFile = $processedEntry.RelativePath
    
    Write-Verbose "Processing file ($fileCounter/$totalFiles): $($currentFileToProcess.FullName)"

    $separatorText = Get-FileSeparator -LocalFileInfo $currentFileToProcess -LocalRelativePath $currentRelativePathForFile -Style $SeparatorStyle
    Add-Content -Path $currentFinalOutputFile -Value $separatorText
    
    if ($SeparatorStyle -ne 'Markdown') {
        Add-Content -Path $currentFinalOutputFile -Value "" # Extra newline for non-markdown styles after separator
    }
    
    try {
        # Read content as raw text. If -IncludeBinaryFiles is used for an actual binary,
        # this will attempt to read it as text, which is consistent with the warning.
        # Using -Raw is generally faster for text files than line-by-line.
        $content = Get-Content -Path $currentFileToProcess.FullName -Raw -ErrorAction Stop
        Add-Content -Path $currentFinalOutputFile -Value $content
    } catch {
        $errorMessage = "[ERROR: UNABLE TO READ FILE '$($currentFileToProcess.FullName)'. REASON: $($_.Exception.Message)]"
        Write-Warning $errorMessage
        Add-Content -Path $currentFinalOutputFile -Value $errorMessage
    }
    
    $closingSeparatorText = Get-ClosingSeparator -Style $SeparatorStyle
    if ($null -ne $closingSeparatorText) {
        Add-Content -Path $currentFinalOutputFile -Value $closingSeparatorText
    }
    
    # Add a final empty line after each file's block (content + closing separator) for spacing
    Add-Content -Path $currentFinalOutputFile -Value "" 
}

Write-Host "All $totalFiles processed files have been combined into '$currentFinalOutputFile'." -ForegroundColor Green
exit 0 # Explicit successful exit