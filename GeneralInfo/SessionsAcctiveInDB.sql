--Author: Martin Tydor
--
--Description:
--Script for checking currently running queries with useful details

;WITH task_space_usage 
     AS ( 
        SELECT session_id, 
               request_id, 
               Sum(internal_objects_alloc_page_count)   AS alloc_pages, 
               Sum(internal_objects_dealloc_page_count) AS dealloc_pages 
         FROM   sys.dm_db_task_space_usage WITH (nolock) 
         WHERE  session_id <> @@SPID 
         GROUP  BY session_id, request_id) 
SELECT	SES.original_login_name
		,con.client_net_address
		,TSU.session_id
		,ERQ.blocking_session_id as Block_ses_id
		,CONVERT(VARCHAR(10),Datediff(ss,erq.start_time,GETDATE())/(60*60*24)) + 'd  '
			+CONVERT(VARCHAR(8),DateAdd(SS,Datediff(ss,erq.start_time, GETDATE())%(60*60*24),0),114) as RunningTime
		,TSU.alloc_pages * 1.0 / 128   AS [int.object MB]
		,TSU.dealloc_pages * 1.0 / 128 AS [int.ob.dealloc MB]  
		,ERQ.status
		,ERQ.wait_type 
		,ERQ.wait_time/1000 as WaitTimeInSeconds
		,cast (ERQ.percent_complete as decimal (5,2)) as percent_complete
		,SES.total_elapsed_time
		,ior.io_pending_ms_ticks as waittime
		,DB_Name (ERQ.database_id) as DBName
        ,format(ERQ.cpu_time, 'N0') cpu_time
        ,format(ERQ.reads * 8, 'N0') reads
        ,format(ERQ.writes * 8, 'N0') writes
        ,format(ERQ.logical_reads, 'N0') logical_reads
		,isnull (EST.text,AltText.Text) as Query
		,ERQ.estimated_completion_time
		,ERQ.open_resultset_count
		,ERQ.granted_query_memory
		,ERQ.lock_timeout
		,MG.requested_memory_kb
        ,MG.granted_memory_kb
        ,MG.required_memory_kb
        ,MG.used_memory_kb
        ,MG.max_used_memory_kb
        ,MG.query_cost
		,MG.wait_order
		,MG.is_next_candidate
		,MG.queue_id
		,MG.grant_time
        ,ERQ.wait_resource
        ,SES.group_id
		,CASE ses.transaction_isolation_level
				WHEN 0 THEN 'Unspecified'
				WHEN 1 THEN 'Read Uncommitted'
				WHEN 2 THEN 'Read Committed'
				WHEN 3 THEN 'Repeatable'
				WHEN 4 THEN 'Serializable'
				WHEN 5 THEN 'Snapshot'
			END as IsolationLevel
		,EQP.query_plan 
		,ERQ.last_wait_type
		, Isnull(NULLIF(Substring(EST.text, ERQ.statement_start_offset / 2, 
			CASE	WHEN ERQ.statement_end_offset < ERQ.statement_start_offset THEN 0 
            ELSE(ERQ.statement_end_offset - ERQ.statement_start_offset ) / 2 END), ''), 
			EST.text) AS [statement text]
	   ,ERQ.sql_handle
FROM   task_space_usage AS TSU WITH (NOLOCK)
       inner JOIN sys.dm_exec_requests ERQ WITH (nolock)  ON TSU.session_id = ERQ.session_id  AND TSU.request_id = ERQ.request_id 
	   OUTER apply sys.Dm_exec_sql_text(ERQ.sql_handle) AS EST 
       OUTER apply sys.Dm_exec_query_plan(ERQ.plan_handle) AS EQP
       LEFT JOIN sys.dm_exec_sessions SES WITH (NOLOCK) ON SES.session_id=TSU.session_id
       LEFT JOIN sys.dm_exec_query_memory_grants MG WITH (NOLOCK) ON SES.session_id=MG.session_id
	   left join sys.dm_exec_connections as con  WITH (NOLOCK) on con.session_id=TSU.session_id
	   outer APPLY sys.dm_exec_sql_text(most_recent_sql_handle) as AltText
	   left join sys.dm_io_pending_io_requests as ior on ior.io_type = 'disk' and ERQ.sql_handle=ior.io_handle
WHERE  isnull (EST.text,AltText.Text) is not null
ORDER  BY   ERQ.cpu_time DESC