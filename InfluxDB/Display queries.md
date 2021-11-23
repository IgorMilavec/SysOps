
Compute CPU
```
SELECT 100-min("usage_idle") AS "CPU usage" FROM "telegraf"."autogen"."cpu" WHERE time > :dashboardTime: AND time < :upperDashboardTime: AND "host"=':host:' AND "cpu"='cpu-total' GROUP BY time(:interval:) FILL(null)
```

Compute Memory
```
SELECT max("used_percent") AS "Memory used [%]",100-100*min("free")/max("total") AS "Memory used+buff+cache [%]",100-100*min("swap_free")/max("swap_total") AS "Swap used [%]" FROM "telegraf"."autogen"."mem" WHERE time > :dashboardTime: AND time < :upperDashboardTime: AND "host"=':host:' GROUP BY time(:interval:) FILL(null)
```

Storage Space
```
SELECT max("used_percent") AS "Space" FROM "telegraf"."autogen"."disk" WHERE time > :dashboardTime: AND time < :upperDashboardTime: AND "host"=':host:' GROUP BY time(:interval:), "path" FILL(null)
```

Storage Read Latency
```
SELECT non_negative_derivative(last("read_time"),1ms)/non_negative_derivative(last("reads"),1ms) AS "Latency" FROM "telegraf"."autogen"."diskio" WHERE time > :dashboardTime: AND time < :upperDashboardTime: AND "host"=':host:' GROUP BY time(:interval:), "name" FILL(null)
```

Storage Write Latency
```
SELECT non_negative_derivative(last("write_time"),1ms)/non_negative_derivative(last("writes"),1ms) AS "Latency" FROM "telegraf"."autogen"."diskio" WHERE time > :dashboardTime: AND time < :upperDashboardTime: AND "host"=':host:' GROUP BY time(:interval:), "name" FILL(null)
```

Storage Time
```
SELECT 100*non_negative_derivative(last("io_time"),1ms) AS "der_oi_time" FROM "telegraf"."autogen"."diskio" WHERE time > :dashboardTime: AND time < :upperDashboardTime: AND "host"=':host:' GROUP BY time(:interval:), "name" FILL(null)
```

Storage Queue
```
SELECT max("iops_in_progress") AS "max_iops_in_progress" FROM "telegraf"."autogen"."diskio" WHERE time > :dashboardTime: AND time < :upperDashboardTime: AND "host"=':host:' GROUP BY time(:interval:), "name" FILL(null)
```

Storage IOPs
```
SELECT non_negative_derivative(last("reads"))+non_negative_derivative(last("writes"))+non_negative_derivative(last("merged_reads"))+non_negative_derivative(last("merged_writes")) AS "der_oi_time" FROM "telegraf"."autogen"."diskio" WHERE time > :dashboardTime: AND time < :upperDashboardTime: AND "host"=':host:' GROUP BY time(:interval:), "name" FILL(null)
```
