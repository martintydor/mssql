--Author: Martin Tydor
--
--Description:
--Script will synchronize permissions in DB with permissions defined in the script. All additional permissions in DB will be removed, missing will be added


------------ Preparation part --------------------

--prepare tables for final state
drop table if exists #RoleMembersFinal; create table #RoleMembersFinal  (PrincipleType nchar (1) not null, PrincipalName sysname not null,	DBRole nvarchar(128));
drop table if exists #DBPermissionsFinal; create table #DBPermissionsFinal (PrincipleType nchar (1) not null, PrincipalName sysname not null, PermissionState char (1) not null,PermissionName nvarchar(128)  not null);
drop table if exists #SchemaPermissionsFinal; create table #SchemaPermissionsFinal (PrincipleType nchar (1) not null,PrincipalName sysname not null,
	PermissionState char (1) not null,PermissionName nvarchar(128) not null,SchemaName sysname not null);
drop table if exists #ObjectPermissionsFinal; create table #ObjectPermissionsFinal (PrincipleType nchar (1) not null,PrincipalName sysname not null,PermissionState char (1) not null,
	PermissionName nvarchar(128) not null,ObjectName sysname not null);

----------------------------------------------------------------------------------------------
------------------------ definition part for final state - BEGIN -----------------------------
----------------------- Changes must be done only in this place!!! ---------------------------
----------------------------------------------------------------------------------------------
------Membership in roles
------1) Principle Type: S - SQL user, E - AD user, X - AAD Group
------2) Principle Name
------3) Desired role
------
----- EXAMPLE 
------insert into #RoleMembersFinal values ('S','SQLAdmin','db_ddladmin'),
------('E','martin.tydor@zurich.com','db_datareader') 
----------------------------------------------------------------------------------------------

insert into #RoleMembersFinal values 
('S','SQLAdmin','db_ddladmin'),
('S','SQLAdmin','db_datareader'),
('S','SQLAdmin','db_datawriter'),
('E','martin.tydor@zurich.com','db_datareader')

----------------------------------------------------------------------------------------------
------DB Permissions
------1) Principle Type: S - SQL user, E - AD user, X - AAD Group
------2) Principle Name
------3) PermissionsState G - grant, D - Deny
------4) PermissionName (delete, execute, etc)
------
----- EXAMPLE 
------insert into #DBPermissionsFinal values ('S','SQLAdmin','G','VIEW DEFINITION'),
------('E','martin.tydor@zurich.com','G','EXECUTE') 
------CONNECT permission is not needed to define!!!!!!!!!
----------------------------------------------------------------------------------------------

insert into #DBPermissionsFinal values 
('E','tibor.burda@zurich.com','G','VIEW DEFINITION')
,('E','tibor.burda@zurich.com','G','EXECUTE')

----------------------------------------------------------------------------------------------
------DB Schemas permissions
------1) Principle Type: S - SQL user, E - AD user, X - AAD Group
------2) Principle Name
------3) PermissionsState G - grant, D - Deny
------4) PermissionName (delete, execute, etc)
------5) SchemaName
------
----- EXAMPLE 
------insert into #SchemaPermissionsFinal values ('S','SQLAdmin','G','VIEW DEFINITION','TEST'),
------('E','martin.tydor@zurich.com','G','EXECUTE','MySchema') 
----------------------------------------------------------------------------------------------

insert into #SchemaPermissionsFinal values 
('E','martin.tydor@zurich.com','G','EXECUTE','test')
,('E','martin.tydor@zurich.com','G','SELECT','test')
----------------------------------------------------------------------------------------------
------DB Object permissions
------1) Principle Type: S - SQL user, E - AD user, X - AAD Group
------2) Principle Name
------3) PermissionsState G - grant, D - Deny
------4) PermissionName (delete, execute, etc)
------5) ObjectName
------
----- EXAMPLE 
------insert into #ObjectPermissionsFinal values ('S','SQLAdmin','G','VIEW DEFINITION','[dbo].[TableTest]')
----------------------------------------------------------------------------------------------

insert into #ObjectPermissionsFinal values 
('E','tibor.burda@zurich.com','G','SELECT','[dbo].[TableTest]')
,('E','tibor.burda@zurich.com','D','DELETE','[dbo].[TableTest]')


-----------------------------------------------------------------------------------------------
------------------------ definition part for final state - END --------------------------------
------------------------- Don't do chages in the next parts!!! --------------------------------
-----------------------------------------------------------------------------------------------


--prepare table for priciple types creation
drop table if exists #PrincipalType; create table #PrincipalType (PrincipleType nchar (1) not null, Command nvarchar (255) not null);
insert into #PrincipalType values
('S','CREATE USER  [@UserName] FOR LOGIN [@UserName] WITH DEFAULT_SCHEMA = [dbo]'),
('E','CREATE USER  [@UserName] from EXTERNAL PROVIDER'),
('X','CREATE USER  [@UserName] from EXTERNAL PROVIDER')
;
--prepare tables for current state
drop table if exists #RoleMembersCurrent; create table #RoleMembersCurrent  (PrincipleType nchar (1) not null, PrincipalName sysname not null,	DBRole nvarchar(128));
drop table if exists #DBPermissionsCurrent; create table #DBPermissionsCurrent (PrincipleType nchar (1) not null, PrincipalName sysname not null, PermissionState char (1) not null,PermissionName nvarchar(128)  not null);
drop table if exists #SchemaPermissionsCurrent; create table #SchemaPermissionsCurrent (PrincipleType nchar (1) not null,PrincipalName sysname not null,
	PermissionState char (1) not null,PermissionName nvarchar(128) not null,SchemaName sysname not null);
drop table if exists #ObjectPermissionsCurrent; create table #ObjectPermissionsCurrent (PrincipleType nchar (1) not null,PrincipalName sysname not null,PermissionState char (1) not null,
	PermissionName nvarchar(128) not null,ObjectName sysname not null);

--gather current DB roles
insert into #RoleMembersCurrent
select dp.type as PrincipleType,dp. name as PrincipalName, USER_NAME(rm.role_principal_id) as DBRole
	FROM    sys.database_principals AS dp
	inner	join sys.database_role_members as rm on dp.principal_id = rm.member_principal_id
	WHERE dp.[type] IN (select PrincipleType COLLATE database_default from #PrincipalType)
           and dp.[principal_id] > 4
	
insert into #DBPermissionsCurrent
select dp.type as PrincipleType, dp.name as PrincipalName, dperm.state as PermissionState, 	dperm.permission_name as PermissionName
	from	sys.database_principals as dp
	inner join sys.database_permissions AS dperm on dperm.grantee_principal_id = dp.principal_id
	WHERE dp.[type] IN (select PrincipleType COLLATE database_default from #PrincipalType)
           and dp.[principal_id] > 4
		   and [dperm].[major_id] = 0
		  -- and dperm.permission_name <>'CONNECT'

insert into #SchemaPermissionsCurrent 
select dp.type as PrincipleType, dp.name as PrincipalName, dperm.state as PermissionState, 
	dperm.permission_name as PermissionName, SCHEMA_NAME(major_id) as SchemaPermission
	from sys.database_principals as dp
	inner join 	sys.database_permissions dperm on dperm.grantee_principal_id = dp.principal_id
	inner join sys.schemas AS ds on  dperm.major_id = ds.schema_id
	WHERE  dp.[type] IN (select PrincipleType COLLATE database_default from #PrincipalType)
           and dp.[principal_id] > 4 and 
		   class = 3 --class 3 = schema

insert into #ObjectPermissionsCurrent 
select dp.type as PrincipleType, dp.name as PrincipalName, dperm.state as PermissionState,  dperm.permission_name as PermissionName, 
	QUOTENAME(SCHEMA_NAME(do.schema_id)) + '.' + QUOTENAME(do.name) + CASE  WHEN cl.column_id IS NULL THEN SPACE(0) ELSE '(' + QUOTENAME(cl.name) + ')' END  as ObjectName
	from	sys.database_principals as dp
	inner join 	sys.database_permissions dperm on dp.principal_id = dperm.grantee_principal_id
	inner join  sys.objects as do on dperm.major_id = do.[object_id]
	left join sys.all_columns as cl on cl.column_id=dperm.minor_id and cl.[object_id] = dperm.major_id
	WHERE dp.[type] IN (select PrincipleType COLLATE database_default from #PrincipalType)
           and dp.[principal_id] > 4
		   and do.type='U' --select only user objects

------------------------------------------------------------------------------------------------------------------------------------
------------------------------ begin of action part --------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------

--changing dbowner for schemas to avoid account own schema and can't be deleted
--update o 
--	set o.principal_id = 1
--	--o.name, o.type_desc, case when o.principal_id is null then s.principal_id else o.principal_id end as principal_id, dp.name as Owner, dp.type
--    from sys.objects o
--    inner join sys.schemas s on o.schema_id = s.schema_id
--	inner join sys.database_principals dp on isnull (o.principal_id,1) = dp.principal_id 
--    where o.is_ms_shipped = 0 and dp.principal_id <>1
--		and dp.type in (select PrincipleType COLLATE database_default from #PrincipalType)
drop table if exists #SyncResul;create table #SyncResul (SyncOrder int IDENTITY(1,1) NOT NULL,	Command nvarchar (4000) not null,	Successful bit not null);
drop table if exists #Command; create table #Command (Command nvarchar (4000) not null);
declare @command as nvarchar (4000)

insert into #Command
	select concat('ALTER AUTHORIZATION ON SCHEMA::[',  s.name,'] TO [dbo]') 
	from sys.schemas as s
	inner join sys.database_principals dp on s.principal_id = dp.principal_id 
	where s.principal_id > 4 
		and dp.type in (select PrincipleType COLLATE database_default from #PrincipalType);

DECLARE db_cursor CURSOR FOR select Command from #Command
OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @command  

WHILE @@FETCH_STATUS = 0  
BEGIN  
	begin try
		exec (@command)
		insert into #SyncResul (Command, Successful) values (@command, 1)
	end try
	begin catch
		insert into #SyncResul (Command, Successful) values (@command, 0)
	end catch
    FETCH NEXT FROM db_cursor INTO @command 
END 

CLOSE db_cursor  
DEALLOCATE db_cursor 
;

--sync principals in DB - drop / create
truncate table #Command;

;with f as (
	select PrincipleType, PrincipalName from #RoleMembersFinal
	union
	select PrincipleType, PrincipalName from #DBPermissionsFinal
	union
	select PrincipleType, PrincipalName from #SchemaPermissionsFinal
	union
	select PrincipleType, PrincipalName from #ObjectPermissionsFinal
), c as (
	select PrincipleType, PrincipalName from #RoleMembersCurrent
	union
	select PrincipleType, PrincipalName from #DBPermissionsCurrent
	union
	select PrincipleType, PrincipalName from #SchemaPermissionsCurrent
	union
	select PrincipleType, PrincipalName from #ObjectPermissionsCurrent
)
insert into #Command
select replace (pt.Command,'@UserName',f.PrincipalName) as Command
	from f 
	left join #PrincipalType as pt on pt.PrincipleType = f.PrincipleType
	left join  c on f.PrincipalName = c.PrincipalName
	where c.PrincipalName is null
union all
select CONCAT('DROP USER [', isnull (c.PrincipalName,'Unknow'), ']') as Command
	from c 
	left join  f on c.PrincipalName = f.PrincipalName
	where f.PrincipalName is null

DECLARE db_cursor CURSOR FOR select Command from #Command
OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @command  

WHILE @@FETCH_STATUS = 0  
BEGIN  
	begin try
		exec (@command)
		insert into #SyncResul (Command, Successful) values (@command, 1)
	end try
	begin catch
		insert into #SyncResul (Command, Successful) values (@command, 0)
	end catch
    FETCH NEXT FROM db_cursor INTO @command 
END 

CLOSE db_cursor  
DEALLOCATE db_cursor 

--sync part for DB roles membership
truncate table #Command;

;with f as (
	select PrincipleType, PrincipalName from #RoleMembersFinal
	union
	select PrincipleType, PrincipalName from #DBPermissionsFinal
	union
	select PrincipleType, PrincipalName from #SchemaPermissionsFinal
	union
	select PrincipleType, PrincipalName from #ObjectPermissionsFinal
), c as (
	select PrincipleType, PrincipalName from #RoleMembersCurrent
	union
	select PrincipleType, PrincipalName from #DBPermissionsCurrent
	union
	select PrincipleType, PrincipalName from #SchemaPermissionsCurrent
	union
	select PrincipleType, PrincipalName from #ObjectPermissionsCurrent
), d as 
(
	select distinct c.PrincipalName
	from c 
	left join  f on c.PrincipalName = f.PrincipalName
	where f.PrincipalName is null
)
insert into #Command
select CONCAT('ALTER ROLE [',f.DBRole,'] ADD MEMBER [',f.PrincipalName,']') as Command
	from #RoleMembersFinal as f
	left join #RoleMembersCurrent c on f.PrincipalName = c.PrincipalName and f.DBRole = c.DBRole
	where c.PrincipalName is null and f.PrincipalName not in (select PrincipalName from d)
union all
select  CONCAT('ALTER ROLE [',c.DBRole,'] DROP MEMBER [',c.PrincipalName,']') as Command
	from #RoleMembersCurrent c 
	left join #RoleMembersFinal f on f.PrincipalName = c.PrincipalName and f.DBRole = c.DBRole
	where f.PrincipalName is null and c.PrincipalName not in (select PrincipalName from d)

DECLARE db_cursor CURSOR FOR select Command from #Command
OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @command  

WHILE @@FETCH_STATUS = 0  
BEGIN  
	begin try
		exec (@command)
		insert into #SyncResul (Command, Successful) values (@command, 1)
	end try
	begin catch
		insert into #SyncResul (Command, Successful) values (@command, 0)
	end catch
    FETCH NEXT FROM db_cursor INTO @command 
END 

CLOSE db_cursor  
DEALLOCATE db_cursor 

--sync part for DB schema
truncate table #Command;

;with f as (
	select PrincipleType, PrincipalName from #RoleMembersFinal
	union
	select PrincipleType, PrincipalName from #DBPermissionsFinal
	union
	select PrincipleType, PrincipalName from #SchemaPermissionsFinal
	union
	select PrincipleType, PrincipalName from #ObjectPermissionsFinal
), c as (
	select PrincipleType, PrincipalName from #RoleMembersCurrent
	union
	select PrincipleType, PrincipalName from #DBPermissionsCurrent
	union
	select PrincipleType, PrincipalName from #SchemaPermissionsCurrent
	union
	select PrincipleType, PrincipalName from #ObjectPermissionsCurrent
), d as 
(
	select distinct c.PrincipalName
	from c 
	left join  f on c.PrincipalName = f.PrincipalName
	where f.PrincipalName is null
)
insert into #Command
select CONCAT(case when f.PermissionState = 'G' then 'GRANT ' else 'DENY ' END, f.PermissionName, ' ON SCHEMA:: [',f.SchemaName,'] TO [',f.PrincipalName,']') as Command
	from #SchemaPermissionsFinal as f
	left join #SchemaPermissionsCurrent c on f.PrincipalName = c.PrincipalName and f.SchemaName  = c.SchemaName and f.PermissionState = c.PermissionState and f.PermissionName = c.PermissionName
	where c.PrincipalName is null and f.PrincipalName not in (select PrincipalName from d)
union all
select  CONCAT('REVOKE ', c.PermissionName, ' ON SCHEMA:: [',c.SchemaName,'] FROM [',c.PrincipalName,']') as Command
	from #SchemaPermissionsCurrent c 
	left join #SchemaPermissionsFinal as f on f.PrincipalName = c.PrincipalName and f.SchemaName  = c.SchemaName and f.PermissionState = c.PermissionState and f.PermissionName = c.PermissionName
	where f.PrincipalName is null and c.PrincipalName not in (select PrincipalName from d)

DECLARE db_cursor CURSOR FOR select Command from #Command
OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @command  

WHILE @@FETCH_STATUS = 0  
BEGIN  
	begin try
		exec (@command)
		insert into #SyncResul (Command, Successful) values (@command, 1)
	end try
	begin catch
		insert into #SyncResul (Command, Successful) values (@command, 0)
	end catch
    FETCH NEXT FROM db_cursor INTO @command 
END 

CLOSE db_cursor  
DEALLOCATE db_cursor 

--sync part for DB  permissions
truncate table #Command;
;with f as (
	select PrincipleType, PrincipalName from #RoleMembersFinal
	union
	select PrincipleType, PrincipalName from #DBPermissionsFinal
	union
	select PrincipleType, PrincipalName from #SchemaPermissionsFinal
	union
	select PrincipleType, PrincipalName from #ObjectPermissionsFinal
), c as (
	select PrincipleType, PrincipalName from #RoleMembersCurrent
	union
	select PrincipleType, PrincipalName from #DBPermissionsCurrent
	union
	select PrincipleType, PrincipalName from #SchemaPermissionsCurrent
	union
	select PrincipleType, PrincipalName from #ObjectPermissionsCurrent
), d as 
(
	select distinct c.PrincipalName
	from c 
	left join  f on c.PrincipalName = f.PrincipalName
	where f.PrincipalName is null
)
insert into #Command
select CONCAT(case when f.PermissionState = 'G' then 'GRANT ' else 'DENY ' END, f.PermissionName, ' TO [',f.PrincipalName,']') as Command
	from #DBPermissionsFinal as f
	left join #DBPermissionsCurrent c on f.PrincipalName = c.PrincipalName and f.PermissionState = c.PermissionState and f.PermissionName = c.PermissionName 
	where c.PrincipalName is null and f.PrincipalName not in (select PrincipalName from d)
union all
select  CONCAT('REVOKE ', c.PermissionName, ' FROM [',c.PrincipalName,']') as Command
	from #DBPermissionsCurrent c 
	left join #DBPermissionsFinal as f on f.PrincipalName = c.PrincipalName and f.PermissionState = c.PermissionState and f.PermissionName = c.PermissionName 
	where f.PrincipalName is null and c.PrincipalName not in (select PrincipalName from d)

DECLARE db_cursor CURSOR FOR select Command from #Command
OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @command  

WHILE @@FETCH_STATUS = 0  
BEGIN  
	begin try
		exec (@command)
		insert into #SyncResul (Command, Successful) values (@command, 1)
	end try
	begin catch
		insert into #SyncResul (Command, Successful) values (@command, 0)
	end catch
    FETCH NEXT FROM db_cursor INTO @command 
END 

CLOSE db_cursor  
DEALLOCATE db_cursor


--sync part for DB object permissions
truncate table #Command;
;with f as (
	select PrincipleType, PrincipalName from #RoleMembersFinal
	union
	select PrincipleType, PrincipalName from #DBPermissionsFinal
	union
	select PrincipleType, PrincipalName from #SchemaPermissionsFinal
	union
	select PrincipleType, PrincipalName from #ObjectPermissionsFinal
), c as (
	select PrincipleType, PrincipalName from #RoleMembersCurrent
	union
	select PrincipleType, PrincipalName from #DBPermissionsCurrent
	union
	select PrincipleType, PrincipalName from #SchemaPermissionsCurrent
	union
	select PrincipleType, PrincipalName from #ObjectPermissionsCurrent
), d as 
(
	select distinct c.PrincipalName
	from c 
	left join  f on c.PrincipalName = f.PrincipalName
	where f.PrincipalName is null
)
insert into #Command
select CONCAT(case when f.PermissionState = 'G' then 'GRANT ' else 'DENY ' END, f.PermissionName, ' ON ',f.ObjectName ,' TO [',f.PrincipalName,']') as Command
	from #ObjectPermissionsFinal as f
	left join #ObjectPermissionsCurrent c on f.PrincipalName = c.PrincipalName and f.PermissionState = c.PermissionState and f.PermissionName = c.PermissionName and f.ObjectName = c.ObjectName
	where c.PrincipalName is null and f.PrincipalName not in (select PrincipalName from d)
union all
select  CONCAT('REVOKE ', c.PermissionName, ' ON ',c.ObjectName,' FROM [',c.PrincipalName,']') as Command
	from #ObjectPermissionsCurrent c 
	left join #ObjectPermissionsFinal as f on f.PrincipalName = c.PrincipalName and f.PermissionState = c.PermissionState and f.PermissionName = c.PermissionName and f.ObjectName = c.ObjectName
	where f.PrincipalName is null and c.PrincipalName not in (select PrincipalName from d)

DECLARE db_cursor CURSOR FOR select Command from #Command
OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @command  

WHILE @@FETCH_STATUS = 0  
BEGIN  
	begin try
		exec (@command)
		insert into #SyncResul (Command, Successful) values (@command, 1)
	end try
	begin catch
		insert into #SyncResul (Command, Successful) values (@command, 0)
	end catch
    FETCH NEXT FROM db_cursor INTO @command 
END 

CLOSE db_cursor  
DEALLOCATE db_cursor 