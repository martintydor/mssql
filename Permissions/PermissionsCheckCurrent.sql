--Author: Martin Tydor
--
--Description:
--Script for getting current permissions assigned in DB. It doesn't show permissions for particular object (like one view or table) in detail, 
--but still shows there is such a permission

DECLARE @DB_USers TABLE
(DBName sysname, UserName sysname, LoginType sysname, AssociatedRole varchar(max),create_date datetime,modify_date datetime,AssociatedPerm varchar(max))
 
INSERT @DB_USers
SELECT DB_NAME()  AS DB_Name,
	prin.name AS UserName,
	prin.type_desc AS LoginType,
	isnull(USER_NAME(mem.role_principal_id),'') AS AssociatedRole ,create_date,modify_date,
	perm.permission_name AS AssociatedPerm
FROM sys.database_principals prin
	LEFT OUTER JOIN sys.database_role_members mem ON prin.principal_id=mem.member_principal_id
	LEFT JOIN        
    --Role permissions
    sys.database_permissions perm ON perm.[grantee_principal_id] = prin.[principal_id]
WHERE prin.sid IS NOT NULL and prin.sid NOT IN (0x00) and
	prin.is_fixed_role <> 1 AND prin.name NOT LIKE '##%'
	and prin.type in ('S','E','X','U','G');
 
SELECT @@SERVERNAME as ServerName, dbname,username ,logintype ,create_date ,modify_date ,
	STUFF(	 
		(SELECT distinct ',' + CONVERT(VARCHAR(500),associatedrole)
		FROM @DB_USers user2
		WHERE
		user1.DBName=user2.DBName AND user1.UserName=user2.UserName
		FOR XML PATH('')),1,1,'') AS Accesses,
	STUFF(	 
		(SELECT distinct ',' + CONVERT(VARCHAR(500),AssociatedPerm)
		FROM @DB_USers user2
		WHERE
		user1.DBName=user2.DBName AND user1.UserName=user2.UserName
		FOR XML PATH('')),1,1,'') AS [permissions]
FROM @DB_USers user1
where username not in ('checkSRV','public') 
GROUP BY dbname,username ,logintype ,create_date ,modify_date
ORDER BY DBName,username 