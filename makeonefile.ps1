<#
.SYNOPSIS
    Combines the content of multiple files into a single output file.

.DESCRIPTION
    This script combines the content of all files from a specified directory and its subdirectories into a single output file.
    Each file's content is preceded by a separator showing its relative path. The separator format is "======= path/to/file =======".
    
    This is useful for code reviews, documentation, or when you need to share multiple files as a single document.

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

.EXAMPLE
    .\makeonefile.ps1 -SourceDirectory "C:\Projects\MyCode" -OutputFile "C:\Temp\combined_code.txt"
    
    Combines all files from C:\Projects\MyCode and its subdirectories into C:\Temp\combined_code.txt
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
    .\makeonefile.ps1 -SourceDirectory $srcDir -OutputFile $outputPath -Force -AddTimestamp
    
    Shows how to use variables with both the Force and AddTimestamp parameters.

.NOTES
    Author: Franz und Franz
    Date: May 15, 2025
    Version: 1.2
    
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
    [switch]$AddTimestamp
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

# Get all files in the directory and subdirectories
$files = Get-ChildItem -Path $SourceDirectory -File -Recurse

# Process each file
foreach ($file in $files) {
    # Determine the relative path to the file
    # Ensure proper path handling regardless of whether SourceDirectory ends with a backslash
    $normalizedSourcePath = $SourceDirectory.TrimEnd('\') + '\'
    $relativePath = $file.FullName.Substring($normalizedSourcePath.Length)
    
    # Write separator line with relative path and filename
    Add-Content -Path $finalOutputFile -Value ("======= " + $relativePath + " =======")
    # Add an empty line
    Add-Content -Path $finalOutputFile -Value ""
    # Read the content of the file and add it to the output file
    Get-Content -Path $file.FullName | Add-Content -Path $finalOutputFile
    # Add an empty line
    Add-Content -Path $finalOutputFile -Value ""
}

Write-Host "All files have been combined in $finalOutputFile."
