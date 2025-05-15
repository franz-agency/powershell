# Franz.Agency PowerShell Collection

[![Franz.Agency](https://franz.agency/images/logo.svg)](https://franz.agency)

A collection of useful PowerShell scripts developed by [Franz.Agency](https://franz.agency) to automate common tasks and improve workflow efficiency.

## Table of Contents

- [Installation](#installation)
- [Scripts Overview](#scripts-overview)
  - [convert_line_ending.ps1](#convert_line_endingps1)
  - [formattime.ps1](#formattimeps1)
  - [makeonefile.ps1](#makeonefileps1)
  - [translate_directories.ps1](#translate_directoriesps1)
  - [test_translation.ps1](#test_translationps1)
- [DeepL API Integration](#deepl-api-integration)
- [Contributing](#contributing)
- [License](#license)

## Installation

You can clone this repository using the following command:

```powershell
git clone https://github.com/franz-agency/powershell.git
```

Alternatively, you can download individual scripts directly from the repository.

## Scripts Overview

### convert_line_ending.ps1

Converts line endings of files from Windows-style (CRLF) to Unix-style (LF) format, useful for cross-platform development.

#### Features

- Recursively processes files in a directory and its subdirectories
- Filters by file extensions
- Excludes directories that start with a dot (.)
- Supports dry run mode to preview changes without modifying files
- Provides detailed statistics about the conversion process

#### Usage

```powershell
# Perform a dry run (no changes made)
.\convert_line_ending.ps1 -Path "C:\Projects" -Extensions "txt,md,js" -DryRun "yes"

# Perform actual conversion
.\convert_line_ending.ps1 -Path "C:\Projects\Website" -Extensions "html,css,js" -DryRun "no"

# Run with verbose output
.\convert_line_ending.ps1 -Path "C:\Projects" -Extensions "js,html" -DryRun "yes" -Verbose
```

### formattime.ps1

A utility script that formats time spans in a human-readable way. Useful for reporting execution times of scripts or processes.

#### Features

- Formats durations into human-readable strings
- Automatically adjusts output format based on the duration length (milliseconds, seconds, minutes, hours)
- Uses grammatically correct pluralization
- Can be integrated into other scripts to report execution times

#### Usage

```powershell
# Basic usage with default task name
$timeSpan = [TimeSpan]::FromSeconds(125)
Format-TimeSpan -timeSpan $timeSpan

# Custom task name
Format-TimeSpan -timeSpan $timeSpan -taskName "Database backup"

# Measuring and reporting actual execution time
$time = Measure-Command { YourScriptOrCommand }
Format-TimeSpan -timeSpan $time -taskName "The operation"
```

### makeonefile.ps1

Combines the content of all files from a specified directory and its subdirectories into a single output file. Useful for code reviews, documentation, or sharing multiple files as a single document.

#### Features

- Processes all files in a directory tree
- Clearly separates each file's content with a header showing its relative path
- Preserves the original content formatting
- Supports both absolute and relative paths
- Checks for existing output files with confirmation prompt
- Provides option to force overwrite without prompting
- Offers optional timestamp addition to output filenames

#### Usage

```powershell
# Basic usage with absolute paths
.\makeonefile.ps1 -SourceDirectory "C:\Projects\MyCode" -OutputFile "C:\Temp\combined_code.txt"

# Using relative paths
.\makeonefile.ps1 -SourceDirectory ".\src" -OutputFile "combined_src.txt"

# Automatically overwrite existing file without prompting
.\makeonefile.ps1 -SourceDirectory ".\src" -OutputFile "combined_src.txt" -Force

# Add timestamp to output filename (e.g., combined_src_20250515_102030.txt)
.\makeonefile.ps1 -SourceDirectory ".\src" -OutputFile "combined_src.txt" -AddTimestamp

# Using variables with both Force and AddTimestamp parameters
$srcDir = "D:\Projects\WebApp"
$outputPath = "D:\Documentation\WebApp_Full_Source.txt"
.\makeonefile.ps1 -SourceDirectory $srcDir -OutputFile $outputPath -Force -AddTimestamp
```

### translate_directories.ps1

Translates the names of directories and subdirectories in a specified directory using the DeepL API. Useful for creating multilingual versions of file structures.

#### Features

- Translates directory names using DeepL's high-quality translation
- Supports multiple language pairs
- Offers a dry run mode to preview changes
- Excludes hidden directories (starting with a dot)
- Reports detailed statistics about translated directories

#### Usage

```powershell
# Dry run to preview changes
.\translate_directories.ps1 -Directory "C:\Projects\Website" -SourceLang "EN" -TargetLang "DE" -DryRun

# Actual translation
.\translate_directories.ps1 -Directory "C:\Projects\Website" -SourceLang "EN" -TargetLang "DE"
```

#### ⚠️ Warning!

There is no way to automatically revert the directory renaming. Always keep a backup before running this script in non-dry-run mode. Test first with small test directories.

### test_translation.ps1

A utility script to test the DeepL API translation functionality. Useful for verifying API keys and testing translation quality before using the translation in other scripts.

#### Features

- Tests connectivity to the DeepL API
- Handles API key validation
- Demonstrates proper usage of the DeepL API for translation
- Includes example translations with special characters

#### Usage

```powershell
# Run the script to test translation functionality
.\test_translation.ps1
```

## DeepL API Integration

Some scripts in this collection (`translate_directories.ps1` and `test_translation.ps1`) use the [DeepL API](https://www.deepl.com/docs-api/) to perform translations. To use these scripts, you'll need a DeepL API key.

### Getting an API Key

1. Sign up for a DeepL API account at [DeepL Pro](https://www.deepl.com/pro#developer)
2. Choose a plan (free trial or paid)
3. Obtain your API key from the account dashboard

### Configuration

1. Create a `config.ini` file in the repository root (you can copy from `config.ini.template`)
2. Add your API key to the file:
   ```ini
   API_KEY = "your-api-key-here"
   ```

## Contributing

Contributions are welcome! If you have improvements or additional scripts to share, please:

1. Fork the repository
2. Create a new branch for your feature
3. Add your script with proper documentation
4. Submit a pull request

Please ensure all scripts include proper comment-based help and documentation.

## License

These scripts are provided under the MIT License. See the LICENSE file for details.
