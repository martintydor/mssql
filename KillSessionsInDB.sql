--Author: Martin Tydor
--
--Description:
--Generate kill command for all active sessions in DB according to its SID


USE [master];

DECLARE @kill varchar(8000) = '';  
SELECT @kill = @kill + 'kill ' + CONVERT(varchar(5), session_id) + ';'  
FROM sys.dm_exec_sessions
WHERE database_id  = db_id('DBName')

print(@kill);