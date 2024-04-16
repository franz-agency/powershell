# This script converts the line endings of files from CRLF to LF.

# Parameters:
# $path: The path where the files are located.
# $extensions: The file extensions to consider for conversion, separated by commas.
# $drymode: If set to "yes", the script will only simulate the conversion without actually changing the files.

param(
    [string]$path,
    [string]$extensions,
    [string]$drymode = "yes"
)

# Function to convert the line endings of a file from CRLF to LF.
# Parameter:
# $file: The file to convert.

function Convert-CRLFToLF {
    param(
        [string]$file
    )

    # Check if the file exists
    if (Test-Path -Path $file) {
        # Get the content of the file
        $content = Get-Content -Path $file -Raw

        # Check if the content is not null and contains CRLF line endings
        if ($null -ne $content -and $content.Contains("`r`n")) {
            # If drymode is set to "no", replace the CRLF line endings with LF and save the file
            if ($drymode -eq "no") {
                $content = $content -replace "`r`n", "`n"
                Set-Content -Path $file -Value $content -NoNewline
                Write-Output "Converted: $file"
            } else {
                Write-Output "Would convert: $file"
            }
        }
    } else {
        Write-Output "File not found: $file"
    }
}

# Split the extensions parameter into an array
$extensionArray = $extensions -split ","

# Get the directories to exclude (those starting with a dot)
$excludeDirs = Get-ChildItem -Path $path -Directory | Where-Object { $_.Name.StartsWith(".") }

# Get all the files in the path (recursively), excluding the directories starting with a dot
# and only considering the files with the specified extensions
# For each of these files, call the Convert-CRLFToLF function
Get-ChildItem -Path $path -Recurse -File | Where-Object {
    $extensionArray -contains $_.Extension.TrimStart(".") -and
    $excludeDirs -notcontains $_.DirectoryName
} | ForEach-Object {
    Convert-CRLFToLF -file $_.FullName
}