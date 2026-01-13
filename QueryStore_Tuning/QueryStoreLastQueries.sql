--Author: Martin Tydor
--
--Description:
--Returns last 10 executed queries stored in query store


SELECT  top (10) @@SERVERNAME as servername,q.query_id, t.query_sql_text,last_execution_time
    FROM sys.query_store_query_text t 
    JOIN sys.query_store_query q ON t.query_text_id = q.query_text_id 
    order by last_execution_time desc
