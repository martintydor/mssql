--Author: Martin Tydor
--
--Description:
--Script for scaling up or down according to vCore definition and current CPU usage
--MaxVcore - maximal possible vCore value
--MinVCore - minimal possible vCore value
--UpCPUThreshold - value when DB will be scaled up
--DownCPUThreshold - value when DB will be scaled down
--minimalDelayToNextChangeInMinute - menimal time delay between scale change

declare @MaxVCore int = 6;
declare @MinVCore int = 2;
declare @UpCPUThreshold float = 55;
declare @DownCPUThreshold float = 15;
declare @requiredServiceObjective as nvarchar (50) = 'HS_Gen5_'
declare @minimalDelayToNextChangeInMinute as int = 45
declare @DBname as nvarchar (50) = 'sqldb-P-MSSQL-Audit-001'
declare @vCoreRow as nvarchar (100) = '2,4,6,8,10,12,14,16,18,20,24,32,40,80'

drop table if exists #vCores;
select Row_Number() over (order by (select 0)) RowNumber, value vCore 
	into #vCores
	from String_Split(@vCoreRow, ',');

--get current value
declare @avg_cpu_percent as float;
declare @minTime as datetime2
SELECT @avg_cpu_percent = avg ([avg_cpu_percent])
 	FROM [sys].[dm_db_resource_stats]
	where [end_time] > dateadd (minute,-15, getdate());

SELECT @minTime = min (end_time)
 	FROM [sys].[dm_db_resource_stats]

--get current vCore
declare @service_objective as nvarchar (50);
select @service_objective = service_objective from sys.database_service_objectives;

declare @CurrentVCore int;
select @CurrentVCore = reverse(left(reverse(@service_objective), charindex('_', reverse(@service_objective)) -1));

select 'Current state' as CurrentState, @avg_cpu_percent as avg_cpu_percent, @CurrentVCore as CurrentVCore, @minTime as MinTime

declare @CurrentRowNumber int;
select @CurrentRowNumber = RowNumber from #vCores where vCore = @CurrentVCore

--up or down scale if needed
if (@avg_cpu_percent > @UpCPUThreshold and @CurrentVCore < @MaxVCore and DATEDIFF (minute, @minTime, getdate())>@minimalDelayToNextChangeInMinute) begin

	select @requiredServiceObjective = 'HS_Gen5_' + cast ((select vCore from #vCores where RowNumber = @CurrentRowNumber+1) as nvarchar (3))
	select 'UpScale' as activity, @avg_cpu_percent as avg_cpu_percent, @requiredServiceObjective as requiredServiceObjective	
	exec ('ALTER DATABASE ['+@DBname+'] MODIFY (SERVICE_OBJECTIVE = '''+ @requiredServiceObjective +''')');
end
else if (@avg_cpu_percent < @DownCPUThreshold and @CurrentVCore > @MinVCore and DATEDIFF (minute, @minTime, getdate())>@minimalDelayToNextChangeInMinute) begin
		select @requiredServiceObjective = 'HS_Gen5_' + cast ((select vCore from #vCores where RowNumber = @CurrentRowNumber-1) as nvarchar (3))
		select 'DownScale' as activity, @avg_cpu_percent as avg_cpu_percent, @requiredServiceObjective as requiredServiceObjective
		exec ('ALTER DATABASE ['+@DBname+'] MODIFY (SERVICE_OBJECTIVE = '''+ @requiredServiceObjective +''')');	
end