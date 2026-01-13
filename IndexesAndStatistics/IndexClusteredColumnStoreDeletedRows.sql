--Author: Martin Tydor
--
--Description:
--Returns amount of deleted rows in columnstore index

SELECT
    s.name as schemaName,
    t.name AS tableName,
    i.[name] AS [Index],
    rg.[row_group_id],
    rg.[delta_store_hobt_id],
    rg.[state_description],
    rg.[total_rows],
    rg.[deleted_rows],
    rg.[size_in_bytes]
FROM sys.column_store_row_groups AS rg
LEFT OUTER JOIN sys.indexes AS i
left join sys.tables  t on t.object_id = i.object_id
left join sys.schemas s on t.schema_id = s.schema_id
ON
    rg.[object_id] = i.[object_id]
    AND rg.[index_id] =i.[index_id]
    order by deleted_rows desc