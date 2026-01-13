--Author: Martin Tydor
--
--Description:
--Script shows permissions from all accounts and DBs on the on-prem server or managed instance

DECLARE @DB_USers TABLE
	(DBName sysname, UserName sysname null, LoginType sysname, AssociatedRole varchar(max),create_date datetime,modify_date datetime,AssociatedPerm varchar(max),Project  nvarchar (50), PMSM  nvarchar (50))
	INSERT @DB_USers
	EXEC sp_MSforeachdb 'use [?]
	SELECT ''?'' AS DB_Name,
		case prin.name when ''dbo'' then prin.name + '' (''+ (select SUSER_SNAME(owner_sid) from master.sys.databases where name =''?'') + '')'' else prin.name end AS UserName,
		prin.type_desc AS LoginType,
		isnull(USER_NAME(mem.role_principal_id),'''') AS AssociatedRole ,create_date,modify_date, perm.permission_name AS AssociatedPerm
		,isnull (cast (p.value as nvarchar (50)),'''') as Project,isnull (cast (sm.value as nvarchar (50)),'''') as PMSM
		FROM sys.database_principals prin
		LEFT OUTER JOIN sys.database_role_members mem ON prin.principal_id=mem.member_principal_id
		LEFT JOIN        
			--Role permissions
			sys.database_permissions perm ON perm.[grantee_principal_id] = prin.[principal_id]
		left join sys.extended_properties as p on cast (p.name as nvarchar (50)) = ''Project''
		left join sys.extended_properties as sm on cast (sm.name as nvarchar (50)) = ''PM/SM''
		WHERE prin.sid IS NOT NULL and prin.sid NOT IN (0x00) and
		prin.is_fixed_role <> 1 AND prin.name NOT LIKE ''##%''
		and DB_NAME() not in (''master'',''tempdb'',''model'')'
 
	SELECT @@SERVERNAME as ServerName, dbname,username ,logintype ,create_date ,modify_date , STUFF(
	 (SELECT distinct ',' + CONVERT(VARCHAR(500),associatedrole) FROM @DB_USers user2 WHERE	user1.DBName=user2.DBName AND user1.UserName=user2.UserName	FOR XML PATH(''))
	 	,1,1,'') AS Accesses, STUFF( 
	 (SELECT distinct ',' + CONVERT(VARCHAR(500),AssociatedPerm) FROM @DB_USers user2 WHERE	user1.DBName=user2.DBName AND user1.UserName=user2.UserName FOR XML PATH(''))
	 	,1,1,'') AS [permissions], Project,PMSM, GETDATE() as ExtractionDate
	FROM @DB_USers user1
	GROUP BY dbname,username ,logintype ,create_date ,modify_date,Project,PMSM
	order by dbname,username ,logintype ,create_date ,modify_date,Project,PMSM