SELECT  name DatabaseName, 
             recovery_model_desc RecoveryModel,
             logstats.LogUsageMB,
             log_reuse_wait_desc LogReuseWait,
             LastFullBackup, LastLogBackup
FROM    sys.databases
             LEFT JOIN (
                    SELECT backupset.database_name DatabaseName, 
                           MAX(CASE WHEN backupset.type = 'D' THEN backupset.backup_finish_date ELSE NULL END) AS LastFullBackup,
                           MAX(CASE WHEN backupset.type = 'I' THEN backupset.backup_finish_date ELSE NULL END) AS LastDifferentialBackup,
                           MAX(CASE WHEN backupset.type = 'L' THEN backupset.backup_finish_date ELSE NULL END) AS LastLogBackup
                    FROM    msdb.dbo.backupset
                    GROUP BY backupset.database_name
             ) backupstats ON (name = backupstats.DatabaseName)
             LEFT JOIN (
                    SELECT  RTRIM(instance_name) [DatabaseName], 
                                  cntr_value / 1024 LogUsageMB
                    FROM   sys.dm_os_performance_counters 
                    WHERE  object_name = 'SQLServer:Databases'
                           AND counter_name = 'Log File(s) Used Size (KB)'
                           AND instance_name <> '_Total'
             ) logstats ON (name = logstats.DatabaseName)
ORDER BY 1
