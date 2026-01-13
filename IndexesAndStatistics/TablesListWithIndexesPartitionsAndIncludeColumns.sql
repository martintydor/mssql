--Author: Martin Tydor
--
--Description:
--Returns list of tables with indexes, partitions and include columns

SELECT
    QUOTENAME(SCHEMA_NAME(t.schema_id)) AS SchemaName,
    QUOTENAME(t.name) AS TableName,
    QUOTENAME(i.name) AS IndexName,
    i.type_desc,
    i.is_primary_key,
    i.is_unique,
    i.is_unique_constraint,
    STUFF(REPLACE(REPLACE((
        SELECT QUOTENAME(c.name) + CASE WHEN ic.is_descending_key = 1 THEN ' DESC' ELSE '' END AS [data()]
        FROM sys.index_columns AS ic with (NoLock) 
        INNER JOIN sys.columns AS c  with (NoLock) ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 0
        ORDER BY ic.key_ordinal
        FOR XML PATH
    ), '<row>', ', '), '</row>', ''), 1, 2, '') AS KeyColumns,
	PartitionCount,
    STUFF(REPLACE(REPLACE((
        SELECT QUOTENAME(c.name) AS [data()]
        FROM sys.index_columns AS ic with (NoLock) 
        INNER JOIN sys.columns AS c  with (NoLock) ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 1
        ORDER BY ic.index_column_id
        FOR XML PATH
    ), '<row>', ', '), '</row>', ''), 1, 2, '') AS IncludedColumns,
    u.user_seeks,
    u.user_scans,
    u.user_lookups,
    u.user_updates
FROM sys.tables AS t with (NoLock)
INNER JOIN sys.indexes AS i  with (NoLock) ON t.object_id = i.object_id
LEFT JOIN sys.dm_db_index_usage_stats AS u  with (NoLock) ON i.object_id = u.object_id AND i.index_id = u.index_id
LEFT JOIN (select object_id, max (partition_number) as PartitionCount from sys.partitions  with (NoLock) group by object_id) as p on p.object_id = t.object_id
WHERE t.is_ms_shipped = 0
AND i.type <> 0