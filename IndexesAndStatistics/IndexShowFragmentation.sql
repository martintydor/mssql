SELECT i.name, OBJECT_NAME(i.object_id), s.name, ips.avg_fragmentation_in_percent--, irh.index_name, irh.start_time
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'SAMPLED')  ips
inner join sys.indexes i on  i.index_id = ips.index_id and i.object_id = ips.object_id
inner join sys.tables ta on ta.object_id=i.object_id
inner join sys.schemas s on ta.schema_id=s.schema_id
ORDER BY ips.avg_fragmentation_in_percent DESC;