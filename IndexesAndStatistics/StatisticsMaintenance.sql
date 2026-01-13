--Author: Martin Tydor
--
--Description:
--Script will maintain statistics on indexes older then set in HOURS and with rows changed more then modified_rows_percentage 

DECLARE @hours int, @modified_rows_percentage int, @Method as nvarchar (50), @UPDATE_STATEMENT as nvarchar (4000)
DECLARE @OBJECT_NAME nvarchar(128), @INDEX_NAME nvarchar(128), @SCHEMA_NAME nvarchar(128), @PartitionNumber int

SET @hours=24
SET @modified_rows_percentage=5
SET @Method = 'RESAMPLE'

DECLARE statistics_cursor CURSOR FOR
    SELECT  OBJECT_NAME(ios.object_id),i.name, s.name, p.partition_number
    FROM sys.dm_db_index_operational_stats(NULL,NULL,NULL,NULL) ios
	inner join sys.indexes i on  ios.index_id=i.index_id and ios.object_id=i.object_id 
	inner  join sys.tables ta on  ta.object_id=i.object_id
	inner join sys.schemas s on ta.schema_id=s.schema_id
	inner join sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
    WHERE    
		OBJECT_NAME(ios.object_id) NOT LIKE 'sys%'
		and i.type < 5 --not for columnstore
        AND STATS_DATE(ios.object_id, ios.index_id) <=DATEADD(HOUR,-@hours,GETDATE())  
		AND (ios.leaf_insert_count+ ios.leaf_delete_count+ ios.leaf_update_count+ ios.leaf_ghost_count) > p.rows * @modified_rows_percentage / 100;

OPEN statistics_cursor;
FETCH NEXT FROM statistics_cursor INTO @OBJECT_NAME, @INDEX_NAME,@SCHEMA_NAME,@PartitionNumber;

WHILE @@FETCH_STATUS = 0   BEGIN
	if @INDEX_NAME is null 
		SET @UPDATE_STATEMENT=N'UPDATE STATISTICS ['+@SCHEMA_NAME+ '].[' +@OBJECT_NAME+'] with ' + @Method  
	else
		SET @UPDATE_STATEMENT=N'UPDATE STATISTICS ['+@SCHEMA_NAME+ '].[' +@OBJECT_NAME+'] ['+@INDEX_NAME + '] with ' + @Method 
	if @PartitionNumber > 1 
		SET @UPDATE_STATEMENT= @UPDATE_STATEMENT + ' ON PARTITIONS ('+ cast (@PartitionNumber as nvarchar (1000)) + ');'
	PRINT @update_statement;
    EXECUTE (@update_statement);             
  
	FETCH NEXT FROM statistics_cursor INTO @OBJECT_NAME, @INDEX_NAME,@SCHEMA_NAME,@PartitionNumber;
END;

CLOSE statistics_cursor;
DEALLOCATE statistics_cursor;