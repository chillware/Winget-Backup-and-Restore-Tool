<#
.SYNOPSIS
Backup and restore Winget packages across Windows installations.

.DESCRIPTION
This PowerShell script facilitates the backup of Winget package configurations to a JSON file, which can be used to restore the packages on the same or a different machine. It handles packages not available in Winget sources and provides detailed logging of the process.

.PARAMETER ExportPath
Specifies the directory and filename where the Winget packages will be exported to a JSON file.

.PARAMETER JsonPath
Specifies the path to the JSON file from which Winget packages will be restored.
#>

function Get-UniqueFilePath {
    <#
    .DESCRIPTION
    Generates a unique file path by appending a numerical suffix to the filename if the file already exists.
    
    .PARAMETER BaseDirectory
    The directory where the file will be created.
    
    .PARAMETER BaseFileName
    The initial name of the file without its extension.
    
    .PARAMETER Extension
    The file extension to append to the filename.
    #>
    param (
        [string]$BaseDirectory,
        [string]$BaseFileName,
        [string]$Extension
    )
    $counter = 1
    $newPath = Join-Path -Path $BaseDirectory -ChildPath ("$BaseFileName$Extension")
    while (Test-Path $newPath) {
        $newPath = Join-Path -Path $BaseDirectory -ChildPath ("$BaseFileName" + "_$counter" + "$Extension")
        $counter++
    }
    return $newPath
}

function Export-InstalledApps {
    <#
    .DESCRIPTION
    Exports installed Winget packages to a JSON file and logs applications not available from Winget sources.
    #>
    param(
        [string]$ExportPath
    )
    $extension = ".json"
    $fileNameWithoutExtension = [IO.Path]::GetFileNameWithoutExtension($ExportPath)
    if (-not $ExportPath.EndsWith($extension)) {
        $ExportPath += $extension
    }
    $directory = [System.IO.Path]::GetDirectoryName($ExportPath)
    if ([string]::IsNullOrEmpty($directory)) {
        $directory = ".\"
    }
    $ExportPath = Get-UniqueFilePath -BaseDirectory $directory -BaseFileName $fileNameWithoutExtension -Extension $extension
    $nonWingetAppsFile = Get-UniqueFilePath -BaseDirectory $directory -BaseFileName $fileNameWithoutExtension -Extension "_non_winget_apps.txt"
    $logFile = Join-Path -Path $directory -ChildPath "Winget_Backup_Restore_Log.txt"
    "Start exporting at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Add-Content -Path $logFile
    try {
        Start-Process -FilePath "winget" -ArgumentList "export -o `"$ExportPath`"" -NoNewWindow -Wait -RedirectStandardOutput $nonWingetAppsFile
        if (Test-Path $ExportPath) {
            "Export successful. File saved at: $ExportPath" | Write-Host -ForegroundColor Green
            "Non-Winget applications logged at: $nonWingetAppsFile" | Write-Host -ForegroundColor Yellow
            "Export successful. Details saved at: $ExportPath" | Add-Content -Path $logFile
            "Non-Winget apps logged at: $nonWingetAppsFile" | Add-Content -Path $logFile
        } else {
            throw "Winget did not create the expected file. Export may have failed."
        }
    } catch {
        "Failed to export installed applications. Error: $_" | Write-Host -ForegroundColor Red
        $_ | Add-Content -Path $logFile
    } finally {
        "End exporting at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Add-Content -Path $logFile
    }
}

function Import-InstalledApps {
    <#
    .DESCRIPTION
    Restores Winget packages from a JSON file, verifying each package before installation to avoid duplicates.
    #>
    param(
        [string]$JsonPath
    )
    $logFile = Join-Path -Path (Get-Location).Path -ChildPath "Winget_Backup_Restore_Log.txt"
    $logMessage = "Start importing at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Add-Content -Path $logFile -Value $logMessage
    if (-Not (Test-Path $JsonPath)) {
        "JSON file not found at the path: $JsonPath" | Write-Host -ForegroundColor Red
        return
    }
    $appList = Get-Content -Path $JsonPath | ConvertFrom-Json
    $uniqueApps = $appList.Sources.Packages | 
                  Group-Object -Property PackageIdentifier |
                  ForEach-Object { $_.Group | Select-Object -First 1 } |
                  Sort-Object -Property PackageIdentifier
    foreach ($app in $uniqueApps) {
        "Installing $($app.PackageIdentifier)..." | Write-Host -ForegroundColor Yellow
        $installOutput = winget install $app.PackageIdentifier --accept-source-agreements --accept-package-agreements 2>&1
        Write-Host $installOutput
        if ($LASTEXITCODE -ne 0) {
            "Failed to install $($app.PackageIdentifier). Error code: $LASTEXITCODE" | Write-Host -ForegroundColor Red
            "Failed to install $($app.PackageIdentifier). Error: $LASTEXITCODE" | Add-Content -Path $logFile
        } else {
            "$($app.PackageIdentifier) installed successfully." | Write-Host -ForegroundColor Green
            "$($app.PackageIdentifier) installed successfully." | Add-Content -Path $logFile
        }
    }
    $logMessage = "End importing at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Add-Content -Path $logFile -Value $logMessage
}

function Main {
    do {
        $action = Read-Host "Do you want to (E)xport or (I)mport installed applications? (E/I)"
        switch ($action.ToUpper()) {
            "E" {
                $defaultName = Join-Path -Path (Get-Location).Path -ChildPath ("winget_backup_" + (Get-Date -Format "yyyyMMdd") + ".json")
                $exportPath = Read-Host "Enter the full path to save the backup JSON file or press ENTER to use default [$defaultName]"
                if ([string]::IsNullOrWhiteSpace($exportPath)) {
                    $exportPath = $defaultName
                }
                Export-InstalledApps -ExportPath $exportPath
                break
            }
            "I" {
                $jsonPath = Read-Host "Enter the full path to the JSON file you want to restore"
                Import-InstalledApps -JsonPath $jsonPath
                break
            }
            default {
                "Invalid input. Please enter 'E' to backup or 'I' to restore." | Write-Host -ForegroundColor Red
            }
        }
    } while ($action.ToUpper() -ne 'E' -and $action.ToUpper() -ne 'I')
}

# Main script logic to handle direct script execution
if ($args.Count -eq 0) {
    Main
} elseif ($args.Count -eq 1) {
    Import-InstalledApps -JsonPath $args[0]
} else {
    "Usage: WingetBackupRestore.ps1 [path_to_json]" | Write-Host -ForegroundColor Red
}
