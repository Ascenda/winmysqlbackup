# test-mc.ps1
# This script tests the MinIO client (mc) connection to your cloud storage.

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
Write-Banner "WinMySQLBackup - MinIO Client (mc) Connection Test"

# --- Configuration ---
Write-Step "Loading configuration..."
$ConfigPath = Join-Path $PSScriptRoot "backup_config.psd1"

if (-not (Test-Path $ConfigPath)) {
    Write-Error "Configuration file not found at '$ConfigPath'. Please run Initialize-Config.ps1 first."
    exit 1
}

$Config = Import-PowerShellDataFile -Path $ConfigPath
$McAlias = $Config.McAlias
$BucketName = $Config.BucketName

# Assume mc.exe is in the same directory as the script
$McPath = Join-Path $PSScriptRoot "mc.exe"

if (-not (Test-Path $McPath)) {
    Write-Error "Error: 'mc.exe' not found in the script directory."
    exit 1
}

Write-Success "Configuration loaded."

# --- Test File Setup ---
$TestFileName = "mc_test_file_$(Get-Random).txt"
$LocalTestPath = Join-Path $PSScriptRoot $TestFileName
$RemotePath = "$McAlias/$BucketName/$TestFileName"

"This is a test file for the WinMySQLBackup mc connection." | Out-File -FilePath $LocalTestPath -Encoding utf8

# --- Test Execution ---
try {
    Write-Step "1. Uploading test file '$TestFileName' to bucket '$BucketName'..."
    & $McPath cp $LocalTestPath $RemotePath | Out-Null
    Write-Success "Upload command executed."

    Write-Step "2. Verifying file exists in bucket..."
    $listOutput = & $McPath ls $RemotePath
    if ($listOutput -match $TestFileName) {
        Write-Success "Test file found in bucket."
    } else {
        Write-Error "Verification failed. Could not find test file in bucket."
        exit 1
    }

    Write-Step "3. Removing test file from bucket..."
    & $McPath rm $RemotePath | Out-Null
    Write-Success "Remote file removed."

    Write-Banner "MinIO client connection test completed successfully!"
}
catch {
    Write-Error "An error occurred during the test: $($_.Exception.Message)"
    Write-Error "Please check your alias, keys, and bucket name."
    exit 1
}
finally {
    # --- Cleanup ---
    Write-Step "Cleaning up local test file..."
    if (Test-Path $LocalTestPath) {
        Remove-Item $LocalTestPath -Force
        Write-Success "Local test file removed."
    }
}
