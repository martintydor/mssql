--Author: Martin Tydor
--
--Description:
--Script for checking the tables details in database split up to partition level
--NULL value in index name means table is HEAP

SELECT	DB_Name() as DBName, 
		sch.name as schemaname,
		t.name AS TableName,
		format(p.rows, 'N0') RowCounts,
	    i.name as IndexName, 	
		p.partition_number,
		SUM(a.total_pages) * 8 /1024 AS TotalSpaceMB,
        SUM(a.used_pages) * 8 / 1024 AS UsedSpaceMB,
        (SUM(a.total_pages) - SUM(a.used_pages)) * 8 / 1024 AS UnusedSpaceMB
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN sys.schemas sch ON t.schema_id = sch.schema_id 
GROUP BY sch.name ,t.name,format(p.rows, 'N0'),i.name, p.partition_number,
         sch.name, p.partition_id
ORDER BY schemaname, TableName, i.name, partition_number