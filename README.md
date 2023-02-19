# franz.agency powershell collection
Useful Powershell Scripts created with the help of ChatGPT

## translate_directories.ps1
This PowerShell script translates the names of directories and subdirectories in a specified directory using the DeepL API. It accepts a number of parameters, including the source and target languages for translation, the directory to translate, and whether to perform a dry run. The script checks for valid API keys and PowerShell version, and handles errors such as non-existent directories and exceeding the 128KB limit for DeepL translation. The script outputs the number of translated directories at the end, unless in dry-run mode.

### Usage
.\translate_directories.ps1 -Directory "C:\Users\test\Desktop\test" -SourceLang "EN" -TargetLang "DE" -DryRun

### Install
You can clone this repository using the following command:
git clone https://github.com/franz-agency/powershell.git

## DeepL API

This script uses the [DeepL API](https://www.deepl.com/docs-api/) to perform translations. To use this script, you will need a paid API key from DeepL. You can sign up for a free trial or purchase an API key on the [DeepL API website](https://www.deepl.com/pro#developer).

Once you have an API key, you can add it to the `config.ini` file in this repository. If you don't have this file, you can create it from the `config.ini.template` file and add your API key.

### Warning!
There is no way back. The directories are really renamed. So better keep a backup. But you can use the dry-run param to check the translation. Try it first with some small test directories.
