<#
.SYNOPSIS
This script translates the names of directories and subdirectories in a specified directory.

.DESCRIPTION
This script accepts a number of parameters, including the source and target languages for translation,
the directory to translate, and whether to perform a dry run. The script also includes a function to translate
an array of text using the DeepL API, checks for valid API keys and PowerShell version, and handles errors such
as non-existent directories and exceeding the 128KB limit for DeepL translation. The script outputs the number
of translated directories at the end, unless in dry-run mode.

.PARAMETER Directory
Specifies the directory to translate. Defaults to the current location.

.PARAMETER SourceLang
Specifies the source language for translation. Defaults to "DE".

.PARAMETER TargetLang
Specifies the target language for translation. Defaults to "EN".

.PARAMETER DryRun
Indicates whether to perform a dry run, which will output the translations that would occur without actually performing them. Defaults to false.

.EXAMPLE
.\translate_directories.ps1 -Directory "C:\Users\test\Desktop\test" -SourceLang "EN" -TargetLang "DE" -DryRun
Translates all directories and subdirectories in the specified directory from English to German.

.NOTES
Author: Georg Franz with the help of Chat GPT, https://franz.agency
Version: 1.0
Last updated: 2023-02-18
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$Directory = (Get-Location).Path,

    [Parameter(Mandatory = $false)]
    [ValidateSet("BG", "CS", "DA", "DE", "EL", "EN", "ES", "ET", "FI", "FR", "HU", "IT", "JA", "LT", "LV", "NL", "PL", "PT-PT", "PT-BR", "RO", "RU", "SK", "SL", "SV", "ZH")]

    [string]$SourceLang = "DE",

    [Parameter(Mandatory = $false)]
    [ValidateSet("BG", "CS", "DA", "DE", "EL", "EN", "ES", "ET", "FI", "FR", "HU", "IT", "JA", "LT", "LV", "NL", "PL", "PT-PT", "PT-BR", "RO", "RU", "SK", "SL", "SV", "ZH")]

    [string]$TargetLang = "EN",

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

if ($PSVersionTable.PSVersion.Major -lt 7)
{
    Write-Error "Please use PowerShell >= 7, may cause encoding issues"
    Exit 1
}

# Define function to translate directory names with DeepL
function Translate-Array
{
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$InputArray,
        [Parameter(Mandatory = $true)]
        [string]$SourceLanguage,
        [Parameter(Mandatory = $true)]
        [string]$TargetLanguage,
        [Parameter(Mandatory = $true)]
        [string]$ApiKey
    )

    # Check if the total text input exceeds 128KB
    $totalLength = ($InputArray | Measure-Object -Sum Length).Sum
    if ($totalLength -gt 131072)
    {
        Write-Error "The total text input exceeds 128KB. DeepL cannot translate more than 128KB at a time. Please choose directories with less subdirctories."
        exit 1
    }

    # Convert the text array into a URL-encoded string
    $text = ($InputArray | ForEach-Object { "text=$([System.Uri]::EscapeDataString($_) )" }) -join '&'

    # Send the request to the DeepL API
    $url = "https://api.deepl.com/v2/translate"
    $headers = @{ 'Authorization' = "DeepL-Auth-Key $ApiKey" }
    $body = "$text&source_lang=$SourceLanguage&target_lang=$TargetLanguage"
    $response = Invoke-RestMethod -Method 'POST' -Uri $url -Headers $headers -Body $body

    # Convert the translated texts into a PowerShell array
    $translations = $response.translations.text

    # Return the translated array
    return $translations
}

# Check if the configuration file exists
if (-not(Test-Path -Path ".\config.ini"))
{
    Write-Error "Error: Configuration file not found. Please create a config.ini file from the config.ini.template file and add your API key."
    Exit 1
}

# Read the API key from the configuration file
$configFile = Get-Content ./config.ini
$apiKey = $configFile | Select-String -Pattern "API_KEY = " | ForEach-Object {
    $_.ToString().Split("=")[1].Trim() -replace '"', ''
}

# Check if the API key is valid
if ($apiKey -eq "PLEASEADDYOURKEYHERE")
{
    Write-Error "Error: API key not set. Please replace the 'PLEASEADDYOURKEYHERE' string in the config.ini file with your own API key."
    Exit 1
}

if (-not(Test-Path -Path $Directory -PathType Container))
{
    Write-Error "Error: Directory does not exist. Please specify a valid directory path."
    Exit 1
}

if (!$DryRun)
{
    # Ask for user confirmation before starting the renaming process
    $confirmation = Read-Host ("This program translates all directories and subdirectories of`n" +
            "$( $Directory )`n" +
            "from " +
            "($SourceLang)" +
            " into the language " +
            "($TargetLang)" +
            ". `nDo you really want to perform this? `nPlease confirm with the 'y' key. " +
            "Any other key will abort the program")

    if ($confirmation -ne "y")
    {
        Write-Output "Exiting program. No directories have been translated and renamed."
        Exit
    }
}

# Get a list of all directories that are not hidden or in a hidden directory, sorted by depth in reverse order
$directories = Get-ChildItem -Directory -Path $Directory -Recurse -Force |
        Where-Object {
            $_.Name -notlike ".*" -and
                    ($_ | Select-Object -ExpandProperty FullName) -notmatch "\\(\.)[^\\]*" -and
                    ($_ | Select-Object -ExpandProperty FullName) -notmatch "\.([^.]+)+$" -and
                    ($_ | Select-Object -ExpandProperty FullName) -notmatch "\.([^.]+)\\"
        } |
        Sort-Object @{ Expression = { ($_.FullName.Split("\")).Count } } -Descending

# Create an array to store the directory names that will be translated
$translateArray = $directories | Select-Object -ExpandProperty Name

$utf8TranslationArray = @()
foreach ($translatedItem in $translateArray) {
    $utf8Directory = [System.Text.Encoding]::UTF8.GetBytes($translatedItem)
    $utf8String = [System.Text.Encoding]::UTF8.GetString($utf8Directory)
    $utf8TranslationArray += $utf8String
}

if ($utf8TranslationArray.Count -eq 0)
{
    Write-Output "No directories found, nothing translated."
    Exit
}

# Translate and rename each directory as necessary, and count the number of translated directories
$translatedCount = 0
$translatedNames = Translate-Array -InputArray $utf8TranslationArray -SourceLanguage $SourceLang -TargetLanguage $TargetLang -ApiKey $apiKey

Write-Host "Starting translation and renaming process..."

if ($directories.Count -eq $translatedNames.Count)
{
    for ($i = 0; $i -lt $directories.Count; $i++) {

        $directoryName = $directories[$i].Name
        $translatedName = $translatedNames[$i]

        # Check if the translated name is different from the current name, and if neither the source nor target language is empty
        if (($directoryName -ne $translatedName) -and ($directoryName -ne "") -and ($translatedName -ne ""))
        {
            if (!$DryRun)
            {
                # Rename the directory
                Rename-Item -Path $directories[$i].FullName -NewName $translatedName
                Write-Output "Renamed '$( $directories[$i].FullName )' to '$translatedName'"
            }
            else
            {
                # Output the directory name that would be renamed
                Write-Output "Would rename '$( $directories[$i].FullName )' to '$translatedName'"
            }
            $translatedCount ++
        }
        elseif ($directoryName -eq $translatedName)
        {
            Write-Output "Directory '$( $directories[$i].FullName )' is the same, so its not renamed."
        }
        elseif ($directoryName -eq "" -or $translatedName -eq "")
        {
            Write-Output "Directory '$( $directories[$i].FullName )' was not renamed because either the source or target language is empty."
        }
    }
}
else
{
    Write-Error "The number of translated directory names does not match the number of directories, aborting program."
    Write-Output "Directories to translate: $( $directories.Count ) - Translated directories: $( $translatedNames.Count )"
    Write-Host "translateArray: $( $utf8TranslationArray -join ', ' )"
    Write-Host "translatedNames: $( $translatedNames -join ', ' )"
    Exit 1
}

# Output the number of translated directories, unless in dry-run mode
if (!$DryRun)
{
    Write-Output "Translated $translatedCount directories."
}
else
{
    Write-Output "Would translate $translatedCount directories."
}
# End of script