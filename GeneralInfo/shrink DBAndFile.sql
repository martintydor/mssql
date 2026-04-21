EXEC sp_MSForEachDB 'DBCC SHRINKDATABASE (''?'' , 0)'

set nocount on  
SELECT 
      'USE [' + d.name + N']' + CHAR(13) + CHAR(10) 
    + 'DBCC SHRINKFILE (N''' + mf.name + N''' , 0, TRUNCATEONLY)' 
    + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) 
FROM 
         sys.master_files mf 
    JOIN sys.databases d 
        ON mf.database_id = d.database_id 
WHERE d.database_id > 4 --and mf.type_desc = 'LOG'
