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
        Write-Error "The total text input exceeds 128KB. DeepL cannot translate more than 128KB at a time."
        return
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

# Example call to the function, test encoding
$InputArray = @('Käfer', 'Ein lustiger Satz mit Österreich und Co.', 'Blöd ist das nicht. So ein Spaß mit dem Übersetzen.')
$SourceLanguage = 'DE'
$TargetLanguage = 'EN'
$OutputArray = Translate-Array -InputArray $InputArray -SourceLanguage $SourceLanguage -TargetLanguage $TargetLanguage -ApiKey $apiKey
$OutputArray



