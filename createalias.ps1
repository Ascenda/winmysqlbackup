# Set-McAlias.ps1
# A PowerShell script to create an mc alias with input parameters.

Param(
    [Parameter(Mandatory=$true)]
    [string]$AliasName,

    [Parameter(Mandatory=$true)]
    [string]$Url,

    [Parameter(Mandatory=$true)]
    [string]$AccessKey,

    [Parameter(Mandatory=$true)]
    [string]$SecretKey
)

# Assume mc.exe is in the same directory as the script
$McPath = Join-Path $PSScriptRoot "mc.exe"

Write-Host "Attempting to set mc alias: '$AliasName'"
Write-Host "URL: '$Url'"
Write-Host "Access Key: '$AccessKey'"

# Check if mc.exe exists
if (-not (Test-Path $McPath)) {
    Write-Error "Error: mc.exe not found at '$McPath'. Check the path and try again."
    Write-Host "If mc.exe is in your PATH environment variable, you can change `$McPath` in the script to 'mc.exe'."
    exit 1
}

# Run the mc alias set command
try {
    # Use & to execute the program when the path contains spaces
    # Parameters are passed as separate arguments
    & $McPath alias set $AliasName $Url $AccessKey $SecretKey

    Write-Host "Alias '$AliasName' was created successfully!"
}
catch {
    Write-Error "An error occurred while creating the alias: $($_.Exception.Message)"
    Write-Error "Verify that your keys are correct and that you have network access."
}

# --- Update Config File ---
$ConfigPath = Join-Path $PSScriptRoot "backup_config.psd1"
if (Test-Path $ConfigPath) {
    Write-Host "`nUpdating configuration file at '$ConfigPath'..." -ForegroundColor Cyan
    try {
        $Config = Import-PowerShellDataFile -Path $ConfigPath
        $Config.McAlias = $AliasName

        $Content = New-Object System.Collections.ArrayList
        $Content.Add("@{") | Out-Null
        $Config.GetEnumerator() | ForEach-Object {
            $Value = $_.Value
            if ($Value -is [string]) {
                $Value = $Value.Replace("'", "''")
            }
            $Content.Add("    $($_.Name) = '$($Value)'") | Out-Null
        }
        $Content.Add("}") | Out-Null

        $Content | Out-File -FilePath $ConfigPath -Encoding utf8

        $Content | Out-File -FilePath $ConfigPath -Encoding utf8
        Write-Host "Successfully updated McAlias in '$ConfigPath' to '$AliasName'." -ForegroundColor Green
    }
    catch {
        Write-Warning "Could not automatically update '$ConfigPath'. Error: $($_.Exception.Message)"
        Write-Warning "Please update the McAlias manually in the configuration file."
    }
}