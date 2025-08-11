# addmysqlcredential.ps1
# This script securely saves your MySQL credentials for the backup script.

# --- Configuration ---
$ConfigPath = Join-Path $PSScriptRoot "backup_config.psd1"

if (-not (Test-Path $ConfigPath)) {
    Write-Error "Configuration file not found at '$ConfigPath'. Please run Initialize-Config.ps1 first."
    return
}

# Read the existing configuration to get the credential path
$Config = Import-PowerShellDataFile -Path $ConfigPath
$CredentialPath = $Config.CredentialPath

# Get MySQL credentials from the user
$MySQLUser = Read-Host -Prompt "Enter the MySQL username"
$Password = Read-Host -AsSecureString -Prompt "Enter the password for $MySQLUser"

# Create a PSCredential object
$Credential = New-Object System.Management.Automation.PSCredential($MySQLUser, $Password)

# Export the credential object to the file. It will be encrypted for the current user.
try {
    $Credential | Export-CliXml -Path $CredentialPath -Force -ErrorAction Stop
    Write-Host "Successfully saved encrypted credentials to '$CredentialPath'" -ForegroundColor Green
}
catch {
    Write-Error "Failed to save credentials. Error: $($_.Exception.Message)"
    exit 1
}