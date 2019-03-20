SELECT  sys.databases.name,
        MAX(last_user_seek) last_user_seek_after_restart,
        MAX(last_user_scan) last_user_scan_after_restart,
        MAX(last_user_lookup) last_user_lookup_after_restart,
        MAX(last_user_update) last_user_update_after_restart
FROM    sys.databases
        LEFT JOIN sys.dm_db_index_usage_stats ON (databases.database_id = dm_db_index_usage_stats.database_id)
WHERE   databases.database_id > 4
GROUP BY sys.databases.name
ORDER BY sys.databases.name
