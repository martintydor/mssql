--Author: Martin Tydor
--
--Description:
--Returns updated time for all statistics in DB

SELECT	s.Name as SchemaName
		,OBJECT_NAME(ss.object_id) AS [TableName]
		,ss.[name] AS [StatisticName]
		,STATS_DATE(ss.[object_id], ss.[stats_id]) AS [StatisticUpdateDate]
		,sp.rows
		,sp.modification_counter
		,sp.modification_counter * 100 / sp.rows as ChangePercentage
FROM sys.stats as ss
inner join sys.tables ta on ta.object_id=ss.object_id 
inner join sys.schemas s on ta.schema_id=s.schema_id	
cross apply sys.dm_db_stats_properties(ss.object_id, ss.stats_id) sp
WHERE OBJECT_NAME(ss.object_id) NOT LIKE 'sys%'
order by [TableName]
