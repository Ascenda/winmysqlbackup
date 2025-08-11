```
================================================================
           WinMySQLBackup - Workflow & Architecture
================================================================

This tool is designed for a single user to manually run backups on their local machine.


+-----------------+
|      User       |
+-----------------+
       |
       | 1. One-Time Setup
       V
+------------------------------------------------------------------+
| [Initialize-Config.ps1] -> Creates -> [backup_config.psd1]       |
|                                     (Main Configuration)         |
|                                                                  |
| [createalias.ps1]       -> Configures-> [MinIO (mc.exe) Alias]   |
|                                     (Also updates config file)   |
|                                                                  |
| [addmysqlcredential.ps1] -> Creates -> [backup_credential.xml]   |
|                                     (Securely stores password)   |
+------------------------------------------------------------------+


------------------------- ON-DEMAND BACKUP WORKFLOW -------------------------

+-----------------+
|      User       |
+-----------------+
       |
       | 2. Runs Backup Manually
       V
+------------------------------------------------------------------+
|                    [backupdatabase.ps1] Script                   |
|                                                                  |
|  1. Reads settings from -> [backup_config.psd1]                  |
|                                                                  |
|  2. Reads & decrypts credentials from -> [backup_credential.xml] |
|     (Decryption works because the same user is running the script)|
|                                                                  |
|  3. Connects to -> [MySQL DB] -> using -> [mysqldump.exe]        |
|                                                                  |
|  4. Creates temporary local -> [backup.sql] file                 |
|                                                                  |
|  5. Uploads backup via -> [mc.exe] -> to -> [Cloud Storage (S3)] |
|                                                                  |
|  6. Deletes the local -> [backup.sql] file                       |
|                                                                  |
|  7. Displays progress directly in the console.                   |
+------------------------------------------------------------------+

```