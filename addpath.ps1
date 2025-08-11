# Add-MySQLToPath.ps1
# Adds the MySQL Server 8.0 bin directory to the current user's PATH environment variable.

$mysqlBinPath = "C:\Program Files\MySQL\MySQL Server 8.0\bin\"

Write-Host "Attempting to add '$mysqlBinPath' to PATH..."

# Get the current user's PATH variable
$currentPath = [System.Environment]::GetEnvironmentVariable("Path", "User")

# Check if the path already exists to avoid duplicates
if ($currentPath -notlike "*$mysqlBinPath*") {
    # Add the new path to the existing PATH variable
    $newPath = $currentPath + ";" + $mysqlBinPath
    
    # Set the new PATH variable for the current user
    [System.Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    
    Write-Host "The path '$mysqlBinPath' has been added to your user's PATH."
    Write-Host "You need to restart your PowerShell window (or other programs) for the change to take effect."
}
else {
    Write-Host "The path '$mysqlBinPath' already exists in your user's PATH. No changes were made."
}

Write-Host "Current user PATH:"
Write-Host ([System.Environment]::GetEnvironmentVariable("Path", "User"))