# cleanup.ps1
# This script removes the configuration and credential files created by the setup scripts.

# --- Configuration ---
$ConfigPath = Join-Path $PSScriptRoot "backup_config.psd1"
$CredentialPath = Join-Path $PSScriptRoot "backup_credential.xml"

# --- Functions for Cleanup Actions ---

function Remove-ConfigFiles {
    param($ConfigPath, $CredentialPath)
    Write-Host "
--- Removing Configuration and Credential Files ---"
    $filesToRemove = @($ConfigPath, $CredentialPath)

    foreach ($file in $filesToRemove) {
        if (Test-Path $file) {
            $confirmation = Read-Host "Are you sure you want to delete the file '$file'? (y/n)"
            if ($confirmation -eq 'y') {
                Remove-Item $file -Force
                Write-Host "File '$file' has been deleted." -ForegroundColor Green
            } else {
                Write-Host "Skipped deleting file '$file'."
            }
        }
    }
}

# --- Execute Cleanup --- 

Write-Host "Starting the cleanup process for WinMySQLBackup." -ForegroundColor Cyan

Remove-ConfigFiles -ConfigPath $ConfigPath -CredentialPath $CredentialPath

Write-Host "
Cleanup process finished." -ForegroundColor Cyan