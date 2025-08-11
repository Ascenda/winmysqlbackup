# backupdatabase.ps1
# This script performs an on-demand MySQL database backup.

Param()

# --- Helper Functions for Output ---
function Write-Banner {
    param($Message)
    Write-Host "`n================================================================"
    Write-Host "  $Message"
    Write-Host "================================================================`n" -ForegroundColor Green
}

function Write-Success {
    param($Message)
    Write-Host "[+] $Message" -ForegroundColor Green
}

function Write-Step {
    param($Message)
    Write-Host "`n[*] $Message" -ForegroundColor Cyan
}

# --- Start ---
Write-Banner "WinMySQLBackup - On-Demand Backup Utility"

# --- Configuration ---
Write-Step "Loading configuration..."
$ConfigPath = Join-Path $PSScriptRoot "backup_config.psd1"

if (-not (Test-Path $ConfigPath)) {
    Write-Error "Configuration file not found at '$ConfigPath'. Please run Initialize-Config.ps1 first."
    exit 1
}

# Import the configuration
$Config = Import-PowerShellDataFile -Path $ConfigPath

# Import and decrypt the credential object
$CredentialPath = $Config.CredentialPath
if (-not (Test-Path $CredentialPath)) {
    Write-Error "Credential file not found at '$CredentialPath'. Please run addmysqlcredential.ps1 first."
    exit 1
}
$Credential = Import-CliXml -Path $CredentialPath

# Extract the username and password
$MySQLUser = $Credential.UserName
$MySQLPassword = $Credential.GetNetworkCredential().Password

# Assign variables from the config file
$DatabaseName    = $Config.DatabaseName
$MySQLHost       = $Config.MySQLHost
$MySQLPort       = $Config.MySQLPort
$McAlias         = $Config.McAlias
$BucketName      = $Config.BucketName
$MysqlDumpPath   = $Config.MysqlDumpPath
Write-Success "Configuration loaded."

# --- End Configuration ---

# Assume mc.exe is in the same directory as the script
$McPath = Join-Path $PSScriptRoot "mc.exe"

Write-Step "Checking for required tools ('./mc.exe' and '$($MysqlDumpPath)')..."
if (-not (Test-Path $McPath)) {
    Write-Error "Error: 'mc.exe' not found in the script directory."
    exit 1
}
if (-not (Get-Command -Name $MysqlDumpPath -ErrorAction SilentlyContinue)) {
    Write-Error "Error: '$($MysqlDumpPath)' not found. Check MysqlDumpPath in config or that it is in your system PATH."
    exit 1
}
Write-Success "Tools found."

## Dump MySQL database
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupFileName = "$($DatabaseName)_$($Timestamp).sql"
$LocalBackupPath = Join-Path $PSScriptRoot $BackupFileName

Write-Step "Dumping database '$($DatabaseName)' to a local file..."

# Create a temporary options file to securely pass credentials
$TempOptionsPath = Join-Path $PSScriptRoot "my.tmp.cnf"
# Use a .NET StreamWriter to create a UTF-8 file WITHOUT a Byte Order Mark (BOM),
# as mysqldump can be sensitive to it.
$StreamWriter = New-Object System.IO.StreamWriter($TempOptionsPath, $false, (New-Object System.Text.UTF8Encoding($false)))
try {
    $StreamWriter.Write("[client]`n")
    $StreamWriter.Write("user=$($MySQLUser)`n")
    $StreamWriter.Write("password=$($MySQLPassword)`n")
}
finally {
    $StreamWriter.Close()
}

try {
    # Use --defaults-extra-file to read credentials from the temp file.
    # Add recommended flags for a complete and consistent backup.
    # The --verbose flag sends progress to stderr.
    $mysqldumpArgs = "--defaults-extra-file=$($TempOptionsPath)", "--host=$($MySQLHost)", "--port=$($MySQLPort)", "--no-tablespaces", "--single-transaction", "--routines", "--triggers", "--verbose", "--result-file=`"$LocalBackupPath`"", $DatabaseName
    
    # Execute mysqldump, redirecting stderr to a variable. Since --result-file is used, stdout is empty.
    $ErrorOutput = & $MysqlDumpPath $mysqldumpArgs 2>&1

    # Check the exit code of mysqldump.
    if ($LASTEXITCODE -ne 0) {
        # If the exit code is not 0, an error occurred.
        # We throw the captured stderr output as the error message.
        throw $ErrorOutput
    }

    if (-not (Test-Path $LocalBackupPath)) {
        throw "Backup file was not created. Check mysqldump output and file permissions."
    }
    
    # If verbose is on, $ErrorOutput might contain progress info. We can print it for the user.
    if ($ErrorOutput) {
        Write-Host $ErrorOutput
    }
    Write-Success "Database dumped successfully to '$($LocalBackupPath)'."
}
catch {
    # Format the error message from the exception.
    $ErrorMessage = $_.Exception.Message
    Write-Error "An error occurred during the database dump:`n$ErrorMessage"
    
    # Pause the script so the user can read the error.
    Write-Host "`nPress any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}
finally {
    # Ensure the temporary options file is always deleted
    if (Test-Path $TempOptionsPath) {
        Remove-Item $TempOptionsPath -Force
    }
}

Write-Step "Uploading '$($BackupFileName)' to s3://$($BucketName)/..."

try {
    & $McPath cp $LocalBackupPath "$($McAlias)/$($BucketName)/$($BackupFileName)" | Out-Null
    Write-Success "File successfully uploaded to cloud storage."
}
catch {
    Write-Error "An error occurred during upload: $($_.Exception.Message)"
    exit 1
}

Write-Step "Removing local backup file..."
Remove-Item $LocalBackupPath -Force -ErrorAction SilentlyContinue
Write-Success "Local file removed."

Write-Banner "Backup Process Finished Successfully"

Write-Host "
Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
