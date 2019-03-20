SELECT  sys.databases.name database_name, 
        COALESCE(user_count, 0) user_count,
        sys.master_files.type_desc,
        sys.master_files.name,
        sys.master_files.physical_name,
        sys.master_files.state_desc,
        sys.master_files.size * 8 / 1024 size_MB,
        CASE WHEN sys.master_files.type_desc = 'ROWS' THEN 
           'ALTER DATABASE ' + sys.databases.name + ' SET OFFLINE; ALTER DATABASE ' + sys.databases.name + ' MODIFY FILE ( NAME = [' + sys.master_files.name + '], FILENAME = ''' + CAST(SERVERPROPERTY('InstanceDefaultDataPath') AS nvarchar(260)) + sys.databases.name + '.mdf'' );' 
        ELSE
           'ALTER DATABASE ' + sys.databases.name + ' SET OFFLINE; ALTER DATABASE ' + sys.databases.name + ' MODIFY FILE ( NAME = [' + sys.master_files.name + '], FILENAME = ''' + CAST(SERVERPROPERTY('InstanceDefaultLogPath') AS nvarchar(260)) + sys.databases.name + '.ldf'' );' 
        END move_command
FROM    sys.databases
        INNER JOIN sys.master_files ON (sys.databases.database_id = sys.master_files.database_id)
        LEFT JOIN (SELECT dbid, COUNT(*) user_count FROM dbo.sysprocesses GROUP BY dbid) a ON (sys.databases.database_id = dbid)
ORDER BY sys.databases.name
