# Winget Backup and Restore Tool

This PowerShell script enables users to backup and restore their Winget-installed applications across different Windows installations. It's designed to simplify the process of exporting Winget package configurations to a JSON file and subsequently using that file to restore applications on the same or different machines. This tool is especially useful for system migrations, upgrades, or recovery scenarios.

## Features

- **Backup Winget Packages**: Export all installed Winget packages into a JSON file.
- **Restore Winget Packages**: Import packages from a JSON file to restore them on any supported system.
- **Non-Winget Logging**: Automatically logs details about applications that are installed but not available in Winget sources.
- **Error Handling**: Robust error handling to ensure any issues during the export or import processes are clearly communicated.
- **Unique File Naming**: Avoids file overwrites by appending a numerical suffix to filenames if they already exist.

## Requirements

- Windows 10 or higher.
- PowerShell 5.1 or higher.
- Winget installed and configured on your system.

## Installation

No installation is necessary. Simply download the `WingetBackupRestore.ps1` script to your local machine.

## Usage

### Exporting Winget Packages

To export your currently installed Winget packages:

```powershell
./WingetBackupRestore.ps1
```

When prompted, choose `E` to export. You can specify the directory and filename where the JSON file will be saved or use the default provided by the script.

### Importing Winget Packages

To restore Winget packages from a previously saved JSON file:

```powershell
./WingetBackupRestore.ps1
```

When prompted, choose `I` to import. You will need to provide the path to the JSON file from which packages should be restored.

### Command Line Arguments

The script can also be run directly with a path to the JSON file for importing:

```powershell
./WingetBackupRestore.ps1 path_to_your_json_file.json
```

This will start the import process immediately using the specified JSON file.

## Logging

The script logs all operations, including any errors and the list of applications not available in Winget sources, to a log file in the same directory as the script. This can be useful for auditing and troubleshooting.

## Contributing

Contributions to this script are welcome. Please fork the repository and submit a pull request with your enhancements.

## License

This script is released under the MIT License. See the `LICENSE` file in the repository for full details.

## Support

If you encounter any issues while using this script, please open an issue in the GitHub repository with a detailed description of the problem and the context in which it occurs.
