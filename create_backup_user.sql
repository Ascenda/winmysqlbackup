-- ====================================================================
-- Create MySQL Backup User (for localhost and 127.0.0.1)
-- ====================================================================
-- This script creates a dedicated MySQL user with privileges to connect
-- from both 'localhost' and '127.0.0.1', which can resolve common
-- connection issues with client tools.
--
-- Instructions:
-- 1. EDIT THE 3 VARIABLES BELOW.
-- 2. Connect to your MySQL server as an administrator (e.g., root).
-- 3. Execute the entire script.
-- 4. Use the username and password you define below when you run the
--    addmysqlcredential.ps1 PowerShell script.
-- ====================================================================

-- --- EDIT THESE VARIABLES ---
SET @username = 'win_backup_user';
SET @password = 'a_very_strong_and_secure_password';
SET @database_name = 'poc_db';
-- --------------------------

-- Step 1: Create the user for 'localhost' connections.
SET @create_user_localhost = CONCAT('CREATE USER \'', @username, '\'@\'localhost\' IDENTIFIED WITH mysql_native_password BY \'', @password, '\'');
PREPARE stmt1 FROM @create_user_localhost;
EXECUTE stmt1;
DEALLOCATE PREPARE stmt1;

-- Step 2: Create the user for '127.0.0.1' connections.
SET @create_user_ip = CONCAT('CREATE USER \'', @username, '\'@\'127.0.0.1\' IDENTIFIED WITH mysql_native_password BY \'', @password, '\'');
PREPARE stmt2 FROM @create_user_ip;
EXECUTE stmt2;
DEALLOCATE PREPARE stmt2;

-- Step 3: Grant privileges to both users.
-- Grant database-level privileges
SET @grant_db_localhost = CONCAT('GRANT SELECT, SHOW VIEW, TRIGGER, LOCK TABLES, EVENT ON `', @database_name, '`.* TO \'', @username, '\'@\'localhost\'');
PREPARE stmt3 FROM @grant_db_localhost;
EXECUTE stmt3;
DEALLOCATE PREPARE stmt3;

SET @grant_db_ip = CONCAT('GRANT SELECT, SHOW VIEW, TRIGGER, LOCK TABLES, EVENT ON `', @database_name, '`.* TO \'', @username, '\'@\'127.0.0.1\'');
PREPARE stmt4 FROM @grant_db_ip;
EXECUTE stmt4;
DEALLOCATE PREPARE stmt4;

-- Grant global-level privileges
SET @grant_global_localhost = CONCAT('GRANT PROCESS ON *.* TO \'', @username, '\'@\'localhost\'');
PREPARE stmt5 FROM @grant_global_localhost;
EXECUTE stmt5;
DEALLOCATE PREPARE stmt5;

SET @grant_global_ip = CONCAT('GRANT PROCESS ON *.* TO \'', @username, '\'@\'127.0.0.1\'');
PREPARE stmt6 FROM @grant_global_ip;
EXECUTE stmt6;
DEALLOCATE PREPARE stmt6;

-- Step 4: Apply the changes.
FLUSH PRIVILEGES;

SELECT CONCAT('User ', @username, ' created successfully for both localhost and 127.0.0.1.') AS Result;
