# Initialize-Config.ps1
# This script creates the central configuration file (backup_config.psd1) with default values.

$ConfigPath = Join-Path $PSScriptRoot "backup_config.psd1"

if (Test-Path $ConfigPath) {
    Write-Host "Configuration file already exists at '$ConfigPath'. No changes were made."
    return
}

# Define the default configuration as a PowerShell hashtable.
$ConfigData = @{
    DatabaseName    = 'poc_db'
    MySQLHost       = '127.0.0.1'
    MySQLPort       = '3306'
    McAlias         = 'mysqlbackup'
    BucketName      = 'mysql-backup-poc'
    MysqlDumpPath   = 'mysqldump.exe'
    CredentialPath = (Join-Path $PSScriptRoot "backup_credential.xml")
}

# Build the string content for the .psd1 file from the hashtable.
$Content = New-Object System.Collections.ArrayList
$Content.Add("@{") | Out-Null
$ConfigData.GetEnumerator() | ForEach-Object {
    $Value = $_.Value
    if ($Value -is [string]) {
        $Value = $Value.Replace("'", "''")
    }
    $Content.Add("    $($_.Name) = '$($Value)'") | Out-Null
}
$Content.Add("}") | Out-Null

# Write the content to the file.
$Content | Out-File -FilePath $ConfigPath -Encoding utf8

Write-Host "Successfully created configuration file at '$ConfigPath'."
Write-Host "Please open and edit this file to match your environment settings before proceeding."