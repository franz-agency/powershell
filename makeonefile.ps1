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
    The path where the combined output file will be created. If this file already exists, it will be deleted before the new file is created.
    This parameter accepts both absolute and relative paths. If a relative path is provided, it will be resolved based on the current working directory.

.EXAMPLE
    .\makeonefile.ps1 -SourceDirectory "C:\Projects\MyCode" -OutputFile "C:\Temp\combined_code.txt"
    
    Combines all files from C:\Projects\MyCode and its subdirectories into C:\Temp\combined_code.txt

.EXAMPLE
    .\makeonefile.ps1 -SourceDirectory ".\src" -OutputFile "combined_src.txt"
    
    Combines all files from the src directory relative to the current location into combined_src.txt in the current directory.

.EXAMPLE
    $srcDir = "D:\Projects\WebApp"
    $outputPath = "D:\Documentation\WebApp_Full_Source.txt"
    .\makeonefile.ps1 -SourceDirectory $srcDir -OutputFile $outputPath
    
    Shows how to use variables to specify the source directory and output file.

.NOTES
    Author: User
    Date: May 15, 2025
    Version: 1.1
    
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
    [string]$OutputFile
)

# Delete the output file if it already exists
if (Test-Path $OutputFile) {
    Remove-Item $OutputFile
}

# Get all files in the directory and subdirectories
$files = Get-ChildItem -Path $SourceDirectory -File -Recurse

# Process each file
foreach ($file in $files) {
    # Determine the relative path to the file
    $relativePath = $file.FullName.Substring($SourceDirectory.Length + 1)
    
    # Write separator line with relative path and filename
    Add-Content -Path $OutputFile -Value ("======= " + $relativePath + " =======")
    # Add an empty line
    Add-Content -Path $OutputFile -Value ""
    # Read the content of the file and add it to the output file
    Get-Content -Path $file.FullName | Add-Content -Path $OutputFile
    # Add an empty line
    Add-Content -Path $OutputFile -Value ""
}

Write-Host "All files have been combined in $OutputFile."
