--Author: Martin Tydor
--
--Description:
--Maintenance for index fragmentation. If >30 then rebuild, if >10 and <30 then reorganize
--Returns final state after the execution

	--Initial check - You must be SysAdmin
	-- Variable/parameters Declaration
	DECLARE @dbname NVARCHAR(128);
	DECLARE @ReorganizeOrRebuildCommand NVARCHAR(MAX);
	DECLARE @dbid INT;
	DECLARE @indexStatisticsScanningMode VARCHAR(20);
	DECLARE @dynamic_command NVARCHAR(1024);
	DECLARE @dynamic_command_get_tables NVARCHAR(MAX);

	--Initializations - Do not change
	SET @dynamic_command = NULL;
	SET @dynamic_command_get_tables = NULL;

	SET NOCOUNT ON;

	--sets the scanning mode for index statistics 
	--available values: 'DEFAULT', NULL, 'LIMITED', 'SAMPLED', or 'DETAILED'
	SET @indexStatisticsScanningMode='SAMPLED';


	-- Temporary table for storing index fragmentation details
	DROP TABLE IF EXISTS #tmpFragmentedIndexesCurrentState
	;
	CREATE TABLE #tmpFragmentedIndexesCurrentState
		(
			[dbName] sysname,
			[tableName] sysname,
			[schemaName] sysname,
			[indexName] sysname,
			[indexType] nvarchar (60),
			[indexTypeId] int,
			[databaseID] SMALLINT ,
			[objectID] INT ,
			[indexID] INT ,
			[partitionID] INT,
			[avgFragmentationPercentage] FLOAT,
			[pageCount] int,
		    [reorganizationOrRebuildCommand] int,
			[done] bit NULL
		);
	
	INSERT INTO #tmpFragmentedIndexesCurrentState (
				[dbName],[tableName],[schemaName],[indexName],[indexType],[indexTypeId],
				[databaseID],[objectID],[indexID],[PartitionID],[AvgFragmentationPercentage],
				[PageCount],[reorganizationOrRebuildCommand],[done])
	SELECT 
		DB_NAME() as [dbName], 
		tbl.name as [tableName],
		SCHEMA_NAME (tbl.schema_id) as schemaName, 
		idx.Name as [indexName], 
		idx.type_desc as [indexType],
		idx.type as [indexTypeId],
		pst.database_id as [databaseID], 
		pst.object_id as [objectID], 
		pst.index_id as [indexID], 
		pst.partition_number as [PartitionID],
		pst.avg_fragmentation_in_percent as [AvgFragmentationPercentage],
		pst.page_count as [PageCount],
		case 
		when idx.type in (0,1,2) --heap, clustered, non-clustered
			and pst.avg_fragmentation_in_percent > 30 --and pst.page_count>500 
				THEN --rebuild
					1
			when idx.type in (0,1,2) --heap, clustered, non-clustered		
			and pst.avg_fragmentation_in_percent > 10 AND pst.avg_fragmentation_in_percent <= 30 THEN --reorganize
					2
		when idx.type in (5,6) --columnstore clustered, non-clustered
			and pst.avg_fragmentation_in_percent > 10
			then 
					1
		ELSE
				NULL
	end as [reorganizationOrRebuildCommand],
	NULL as [done]
	FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL , @indexStatisticsScanningMode) as pst
	INNER JOIN sys.tables as tbl ON pst.object_id = tbl.object_id
	INNER JOIN sys.indexes idx ON pst.object_id = idx.object_id AND pst.index_id = idx.index_id
	WHERE pst.index_id != 0 and pst.alloc_unit_type_desc = 'IN_ROW_DATA'
	    and pst.page_count>500
  

	declare @total as int 
	select @total=count (*) from #tmpFragmentedIndexesCurrentState where reorganizationOrRebuildCommand is not null
	
	print 'Total indexes for clean up: ' +cast (@total as nvarchar (10))
	print 'Starting Rebuild';
	declare @databaseID SMALLINT, @objectID INT, @indexID INT, @PartitionID int
	
	--start rebuild
	DECLARE reorganizeOrRebuildCommands_cursor CURSOR
	FOR
		SELECT  DISTINCT i.[databaseID],i.[objectID],i.[indexID], i.[partitionID],
			case when ic.count = 1 then 
				'ALTER INDEX ['+[indexName]+'] ON ['+[dbName]+'].['+[schemaName]+'].['+[tableName]+'] REBUILD '
			else 
				'ALTER INDEX ['+[indexName]+'] ON ['+[dbName]+'].['+[schemaName]+'].['+[tableName]+'] REBUILD PARTITION = ' + cast (i.[partitionID] as nvarchar (10))
				end as reorganizationOrRebuildCommand			
			FROM #tmpFragmentedIndexesCurrentState as i
			left join (Select [databaseID],[objectID],[indexID], [partitionID], count(PartitionID) over (Partition By  [databaseID],[objectID],[indexID] )  as count from #tmpFragmentedIndexesCurrentState) as ic 
				on i.[databaseID]= ic.[databaseID] and i.[objectID]=ic.[objectID]  and i.[indexID]=ic.[indexID] and i.[partitionID]=ic.[partitionID]
			WHERE i.[reorganizationOrRebuildCommand] = 1 --needed rebuild 
	OPEN reorganizeOrRebuildCommands_cursor;
	FETCH NEXT FROM reorganizeOrRebuildCommands_cursor INTO  @databaseID, @objectID, @indexID, @PartitionID, @ReorganizeOrRebuildCommand;
	WHILE @@fetch_status = 0  
	BEGIN   
		print @ReorganizeOrRebuildCommand;
		begin try
			print @ReorganizeOrRebuildCommand
			EXEC (@ReorganizeOrRebuildCommand); 
			update #tmpFragmentedIndexesCurrentState set done = 1 
				where [databaseID]=@databaseID and [objectID]=@objectID and [indexID]=@indexID 	and  partitionID=@PartitionID
			
		end try
		begin catch
		end catch
	--	end catch
	END;

	CLOSE reorganizeOrRebuildCommands_cursor;
	DEALLOCATE reorganizeOrRebuildCommands_cursor;
	
	--start reorganize
	print 'Starting reorganize';
	DECLARE reorganizeOrRebuildCommands_cursor CURSOR
	FOR
		SELECT  DISTINCT i.[databaseID],i.[objectID],i.[indexID], i.[partitionID],
			case when ic.count = 1 then 
				'ALTER INDEX ['+[indexName]+'] ON ['+[dbName]+'].['+[schemaName]+'].['+[tableName]+'] REORGANIZE;' 
			else
				'ALTER INDEX ['+[indexName]+'] ON ['+[dbName]+'].['+[schemaName]+'].['+[tableName]+'] REORGANIZE PARTITION = ' + cast (i.[partitionID] as nvarchar (10))
			end as reorganizationOrRebuildCommand
			FROM #tmpFragmentedIndexesCurrentState as i
			left join (Select [databaseID],[objectID],[indexID], [partitionID], count(PartitionID) over (Partition By  [databaseID],[objectID],[indexID] )  as count from #tmpFragmentedIndexesCurrentState) as ic 
					on i.[databaseID]= ic.[databaseID] and i.[objectID]=ic.[objectID]  and i.[indexID]=ic.[indexID] and i.[partitionID]=ic.[partitionID]
			WHERE [reorganizationOrRebuildCommand] = 2 --needed reorganize 

	OPEN reorganizeOrRebuildCommands_cursor;
	FETCH NEXT FROM reorganizeOrRebuildCommands_cursor INTO  @databaseID, @objectID, @indexID, @PartitionID, @ReorganizeOrRebuildCommand;
	WHILE @@fetch_status = 0  
	BEGIN   
		begin try 
			print @ReorganizeOrRebuildCommand ;
			EXEC (@ReorganizeOrRebuildCommand);  
			update #tmpFragmentedIndexesCurrentState set done = 1 
				where [databaseID]=@databaseID and [objectID]=@objectID and [indexID]=@indexID 	and  partitionID=@PartitionID		
		end try
		begin catch
		end catch
		FETCH NEXT FROM reorganizeOrRebuildCommands_cursor INTO  @databaseID, @objectID, @indexID, @PartitionID, @ReorganizeOrRebuildCommand;
	END;

	CLOSE reorganizeOrRebuildCommands_cursor;
	DEALLOCATE reorganizeOrRebuildCommands_cursor;


    Select GETDATE() as LOAD_DATE, dbName, tableName, schemaName, [indexTypeId], indexName, [indexType], partitionID, avgFragmentationPercentage, pageCount, 
		case when done is null then 0 else 1 end as done, 0 as isSentByEMail  
		from #tmpFragmentedIndexesCurrentState;