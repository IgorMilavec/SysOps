DECLARE @db_name NVARCHAR(128)
SET     @db_name = '...' 

DECLARE @recovery_point_time DATETIME
SET     @recovery_point_time = '...'


DECLARE @backup_set_id_full INT
SELECT  @backup_set_id_full = MAX(backup_set_id)
FROM    msdb.dbo.backupset
WHERE   database_name = @db_name 
    AND type = 'D'and is_copy_only = '0'
    AND (backup_start_date < @recovery_point_time OR @recovery_point_time IS NULL)

DECLARE @backup_set_id_diff INT
SELECT  @backup_set_id_diff = MAX(backup_set_id)
FROM    msdb.dbo.backupset
WHERE   database_name = @db_name
    AND type = 'I'
    AND backup_set_id > @backup_set_id_full
    AND (backup_start_date < @recovery_point_time OR @recovery_point_time IS NULL)

DECLARE @backup_set_id_last INT
SELECT  @backup_set_id_last = MAX(backup_set_id)
FROM    msdb.dbo.backupset
WHERE   database_name = @db_name 
    AND type = 'L'
    AND backup_set_id >= COALESCE(@backup_set_id_diff, @backup_set_id_full)
    AND (backup_start_date < @recovery_point_time OR @recovery_point_time IS NULL)


SELECT  backup_set_id,
        'RESTORE DATABASE [' + @db_name + '] FROM DISK = N''' + physical_device_name + ''' WITH NORECOVERY; --, REPLACE;' AS Script
FROM    msdb.dbo.backupset bs
        INNER JOIN msdb.dbo.backupmediafamily bmf ON (bs.media_set_id = bmf.media_set_id)
WHERE   backup_set_id = @backup_set_id_full
UNION
SELECT  backup_set_id ,
        'RESTORE DATABASE [' + @db_name + '] FROM DISK = N''' + physical_device_name + ''' WITH NORECOVERY;' AS Script
FROM    msdb.dbo.backupset bs
        INNER JOIN msdb.dbo.backupmediafamily bmf ON (bs.media_set_id = bmf.media_set_id)
WHERE   backup_set_id = @backup_set_id_diff
UNION
SELECT  backup_set_id ,
        'RESTORE LOG      [' + @db_name + '] FROM DISK = N''' + physical_device_name + ''' WITH NORECOVERY' + CASE WHEN  backup_set_id = @backup_set_id_last AND  @recovery_point_time IS NOT NULL THEN ', STOPAT = ''' + convert(varchar(25), @recovery_point_time, 126) + '''' ELSE '' END + ';'  AS Script
FROM    msdb.dbo.backupset bs
        INNER JOIN msdb.dbo.backupmediafamily bmf ON (bs.media_set_id = bmf.media_set_id)
WHERE   database_name = @db_name 
    AND type = 'L'
    AND backup_set_id >= COALESCE(@backup_set_id_diff, @backup_set_id_full)
    AND backup_set_id <= @backup_set_id_last
UNION
SELECT  2147483647 AS backup_set_id ,
        'RESTORE DATABASE [' + @db_name + '] WITH RECOVERY;' AS Script
ORDER BY backup_set_id
