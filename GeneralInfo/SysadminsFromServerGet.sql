--Author: Martin Tydor
--
--Description:
--Script for checking sysadmins from server - gets all sysadmins on the server.

SELECT   @@SERVERNAME as ServerName, GETDATE() as ExtractedDate, 'SERVER' SQL_Level, 'sysadmin' as Role_Or_DB_Name, name as Login_Or_User_name
FROM     master.sys.server_principals 
WHERE    IS_SRVROLEMEMBER ('sysadmin',name) = 1
ORDER BY name