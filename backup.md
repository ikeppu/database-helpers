# Make backup

Backup Query
BACKUP DATABASE YourDatabase TO DISK = 'C:\YourBackupPath\FullBackup.bak';
Schedule Regular Backups
BACKUP DATABASE YourDatabase TO DISK = 'C:\YourBackupPath\DailyBackup.bak' WITH SCHEDULE = 'Daily at 2:00 AM';
Store Backups Safely
BACKUP DATABASE YourDatabase TO URL = 'https://YourCloudStorage/YourBackupPath/Backup.bak';

# Restore backup

Restore Table
RESTORE TABLE YourTable FROM DISK = 'C:\YourBackupPath\Backup.bak';

Restore Database
RESTORE DATABASE YourDatabase FROM DISK = 'C:\YourBackupPath\SystemFailureBackup.bak';
