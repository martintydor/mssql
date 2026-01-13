--Author: Martin Tydor
--
--Description:
--Drops all users in DB. Error could occur when user owns schema or any other object

DECLARE @Command nvarchar(max) = ''

SELECT @Command += 'DROP USER ['+name+'];' 
FROM sys.sysusers 
WHERE name not in ('guest', 'INFORMATION_SCHEMA', 'sys','public')
    and name not like 'db%'

exec (@Command);

go