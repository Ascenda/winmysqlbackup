# WinMySQLBackup: On-Demand MySQL Backup for Windows

This project provides a set of PowerShell scripts to perform a simple, on-demand backup of a MySQL database on a Windows machine. The backup is uploaded to a cloud storage provider using the MinIO client (`mc.exe`).

This tool is designed for a single user, such as a developer or administrator, to run backups manually from their own user account.

## Features

*   **On-Demand Backups:** Manually trigger backups whenever you need them.
*   **Secure Credential Storage:** Uses a standard, encrypted file (`backup_credential.xml`) to securely store your MySQL password, tied to your Windows user account.
*   **Cloud Upload:** Backups are uploaded to any S3-compatible cloud storage (e.g., Google Cloud Storage, Amazon S3, MinIO).
*   **Local Cleanup:** The local `.sql` backup file is automatically deleted after a successful upload.
*   **Simple Configuration:** A single, easy-to-read configuration file (`backup_config.psd1`).

## How It Works

The solution consists of a few PowerShell scripts that work together:

1.  **`Initialize-Config.ps1`:** Creates the central configuration file (`backup_config.psd1`).
2.  **`createalias.ps1`:** Configures the MinIO client (`mc.exe`) with your cloud storage credentials and automatically updates the config file.
3.  **`addmysqlcredential.ps1`:** Securely prompts for your MySQL username and password and saves them to an encrypted XML file (`backup_credential.xml`). Only your Windows user account can decrypt this file.
4.  **`backupdatabase.ps1`:** This is the main script you run to perform the backup. It reads the configuration, decrypts the credentials, creates the database dump, uploads it, and cleans up.

## Prerequisites

*   **Windows PowerShell:** The scripts are designed to run on Windows with PowerShell.
*   **MySQL Server:** A running MySQL server instance that you can access.
*   **MinIO Client (`mc.exe`):** The MinIO client is required for uploading the backup. You can download it from the [MinIO website](https://min.io/docs/minio/linux/reference/minio-mc.html) and place it in this directory.
*   **WinSCP:** (Optional) A graphical tool for browsing the files in your cloud storage bucket. You can download it from the [official WinSCP website](https://winscp.net/eng/download.php).
*   **Cloud Storage Bucket:** An S3-compatible cloud storage bucket and the corresponding access key and secret key.

## Setup Instructions

1.  **Clone or Download:** Get the scripts onto your local machine.

2.  **Initialize and Edit Configuration:**

    Run the `Initialize-Config.ps1` script. This only needs to be done once.

    ```powershell
    .\Initialize-Config.ps1
    ```

    Open the newly created `backup_config.psd1` file in a text editor and fill in the values to match your environment (e.g., `DatabaseName`, `MySQLHost`).

3.  **Configure Cloud Storage Alias:**

    Run the `createalias.ps1` script to configure the MinIO client with your cloud storage credentials. This also only needs to be done once.

    ```powershell
    .\createalias.ps1 -AliasName <your-alias> -Url <your-cloud-storage-url> -AccessKey <your-access-key> -SecretKey <your-secret-key>
    ```

4.  **Save MySQL Credentials:**

    Run the `addmysqlcredential.ps1` script to securely save your MySQL password. This only needs to be done once, or whenever your password changes.

    ```powershell
    .\addmysqlcredential.ps1
    ```

## Performing a Backup

Whenever you want to create a backup, simply run the main script:

```powershell
.\backupdatabase.ps1
```

The script will display its progress in the console.

## Cleanup

To remove the configuration and credential files, you can run the `cleanup.ps1` script. It will ask for confirmation before deleting anything.

```powershell
.\cleanup.ps1
```

## Troubleshooting

### Cannot Run PowerShell Scripts

If you see an error like "...cannot be loaded because running scripts is disabled on this system," you need to change your execution policy. Run the following command in a PowerShell window that you **run as administrator**:

```powersell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Confirm the change, and you should be able to run the scripts.

## Restoring a Backup

You can restore a backup file to evaluate it or recover data. The following steps guide you on how to restore the backup to a *new* database for a side-by-side comparison without affecting your original database.

### Step 1: Download the Backup File

First, you need to download the desired `.sql` backup file from your cloud storage bucket.

**Using WinSCP (Graphical Interface):**

1.  Connect to your S3-compatible cloud storage using the credentials you configured.
2.  Navigate to your backup bucket.
3.  Locate the backup file you wish to restore and download it to your local machine.

**Using MinIO Client (Command Line):**

You can also use the `mc.exe` client to copy the file from your bucket to your current directory.

```powershell
# Replace <alias>, <bucket>, and the filename accordingly
.\mc.exe cp <alias>/<bucket>/your_backup_file.sql .
```

### Step 2: Create a New Database for the Restore

Log in to your MySQL server and create a new, empty database where you will restore the backup. This ensures your original database remains untouched.

```sql
-- Connect to MySQL and run this command
CREATE DATABASE my_restored_db;
```

### Step 3: Restore the Backup

Use the `mysql` command-line tool to import the `.sql` file into your newly created database.

Open a command prompt or PowerShell window and run the following command. You will be prompted for your password.

```powershell
# Replace the placeholders with your actual details
mysql -u your_mysql_user -p -h your_mysql_host my_restored_db < path\to\your_backup_file.sql
```

*   `your_mysql_user`: The MySQL user with permissions to the new database.
*   `your_mysql_host`: The hostname or IP address of your MySQL server.
*   `my_restored_db`: The name of the new, empty database you just created.
*   `path\to\your_backup_file.sql`: The local path to the `.sql` file you downloaded.

After the command completes, the data will be restored in the `my_restored_db` database, and you can connect to it to verify its contents.
