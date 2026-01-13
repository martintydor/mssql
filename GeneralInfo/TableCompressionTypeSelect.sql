--Author: Martin Tydor
--
--Description:
--Script shows compression type for all tables in DB

SELECT 
SCHEMA_NAME(sys.objects.schema_id) AS [SchemaName] 
,OBJECT_NAME(sys.objects.object_id) AS [ObjectName] 
,[rows] 
,[data_compression_desc] 
,sys.partitions.[index_id] as [IndexID_on_Table]
,partitions .partition_number
,sys.indexes.type_desc
FROM sys.partitions 
INNER JOIN sys.objects ON sys.partitions.object_id = sys.objects.object_id 
inner join sys.tables on sys.objects.object_id = sys.tables.object_id
INNER JOIN sys.schemas ON sys.tables.schema_id = sys.schemas.schema_id 
INNER JOIN sys.indexes ON  sys.tables.object_id = sys.indexes.object_id  and sys.indexes.index_id = sys.partitions.[index_id]
WHERE   SCHEMA_NAME(sys.objects.schema_id) <> 'SYS'
ORDER BY [rows] desc, [SchemaName],[ObjectName],[IndexID_on_Table]
        