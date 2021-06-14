# Measuring database wait stats with InfluxDB

## Metrics
- database_wait_stats
  - tags:
    - host
    - instance
    - wait_class
  - fields:
    - wait_count (integer)
    - wait_time_ms (integer)

The ```wait_count``` and ```wait_time_ms``` are cumulative counters, which means they need to be derivated on display.

## Collecting metrics for MS SQL

```SQL
select  wait_type, waiting_tasks_count as wait_count, wait_time_ms
from    sys.dm_os_wait_stats 
where   waiting_tasks_count > 0
```

The ```wait_type``` contains fine grained [Types of Waits](https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-os-wait-stats-transact-sql?view=sql-server-ver15#WaitTypes) which you will want to aggregate into classes. 
A good place to start is [sp_BlitzFirst's approach](https://github.com/BrentOzarULTD/SQL-Server-First-Responder-Kit/blob/dev/sp_BlitzFirst.sql#L447). 
sp_BlitzFirst is part of [SQL Server First Responder Kit](https://github.com/BrentOzarULTD/SQL-Server-First-Responder-Kit), which you totally should be using.

## Collecting metrics for Oracle Database

```SQL
select  wait_class, total_waits as wait_count, 10 * time_waited as wait_time_ms 
from    v$system_wait_class 
where   wait_class <> 'Idle'
```

Classes of wait events are documented [here](https://docs.oracle.com/en/database/oracle/oracle-database/19/refrn/classes-of-wait-events.html).

## Displaying metrics
For display you need to use the difference between two consecutive measurements to calculate the average wait time:
```InfluxQL
SELECT  non_negative_derivative(last("wait_time_ms"),1s) / non_negative_derivative(last("wait_count"),1s) AS "avg_wait"
FROM    "telegraf"."autogen"."database_wait_stats" 
WHERE   time > :dashboardTime: AND time < :upperDashboardTime: AND "host"='...' AND "instance"='...' 
GROUP BY time(:interval:), "wait_class" FILL(null)
```
Note that when you extend the dashboard time, the counters will be averaged over increased time spans, making the results less and less relevant.
