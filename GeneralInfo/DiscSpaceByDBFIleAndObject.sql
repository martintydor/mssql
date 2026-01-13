--Author: Martin Tydor
--
--Description:
--Returns disc space occupied by DB files and in detail disc space occupied by DB tables

select
      name as LogicalName
    , filename as FileName
    , convert(decimal(12,2),round(a.size/128.000,2)) as FileSizeMB
    , convert(decimal(12,2),round(fileproperty(a.name,'SpaceUsed')/128.000,2)) as SpaceUsedMB
    , convert(decimal(12,2),round((a.size-fileproperty(a.name,'SpaceUsed'))/128.000,2)) as FreeSpaceMB
from dbo.sysfiles a


select SCHEMA_NAME(sys.objects.schema_id) as SchemaName, sys.objects.name as TableName, sum(reserved_page_count) * 8.0 / 1024 as sizeMB
from sys.dm_db_partition_stats, sys.objects
where sys.dm_db_partition_stats.object_id = sys.objects.object_id
group by SCHEMA_NAME(sys.objects.schema_id), sys.objects.name
order by sizeMB desc 