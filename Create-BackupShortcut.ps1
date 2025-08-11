
# Create-BackupShortcut.ps1
# This script creates a clickable shortcut on your desktop to run the backup.

# --- Configuration ---
$ScriptName = "backupdatabase.ps1"
$ShortcutName = "Run WinMySQLBackup.lnk"
# --- End Configuration ---

function Write-Step {
    param($Message)
    Write-Host "[*] $Message" -ForegroundColor Cyan
}

# Get the absolute path to the script directory
$ScriptDirectory = $PSScriptRoot

# Get the user's Desktop path
$DesktopPath = [System.Environment]::GetFolderPath('Desktop')
$ShortcutPath = Join-Path $DesktopPath $ShortcutName

# Define the full path to the backup script
$TargetScriptPath = Join-Path $ScriptDirectory $ScriptName

# Check if the target script exists
if (-not (Test-Path $TargetScriptPath)) {
    Write-Error "The target script '$TargetScriptPath' was not found."
    exit 1
}

Write-Step "Creating a shortcut on your desktop at: $ShortcutPath"

# Create a WScript.Shell COM object to create the shortcut
$WshShell = New-Object -ComObject WScript.Shell

# Create the shortcut object
$Shortcut = $WshShell.CreateShortcut($ShortcutPath)

# Set the shortcut's properties
# The Target is powershell.exe, with arguments to run our script
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-ExecutionPolicy Bypass -WorkingDirectory `"$ScriptDirectory`" -File `"$TargetScriptPath`""
$Shortcut.WorkingDirectory = $ScriptDirectory
$Shortcut.IconLocation = "powershell.exe, 0" # Use the PowerShell icon
$Shortcut.Description = "Runs the WinMySQLBackup script."

# Save the shortcut file
$Shortcut.Save()

Write-Host "[+] Shortcut created successfully!" -ForegroundColor Green
Write-Host "You can now double-click the '$ShortcutName' icon on your desktop to run a backup."

