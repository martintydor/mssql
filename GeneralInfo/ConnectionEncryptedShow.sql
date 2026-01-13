--Author: Martin Tydor
--
--Description:
--Shows sessions in DB with encrypted connection 

select ses.session_id, con.encrypt_option, ses.host_name, ses.login_name from sys.dm_exec_connections con, sys.dm_exec_sessions ses
where ses.session_id=con.session_id
AND con.encrypt_option ='TRUE'