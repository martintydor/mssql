--Author: Martin Tydor
--
--Description:
--Script returns top 10 queries consumed the most of CPU and IO


-- Worst performing CPU bound queries
SELECT TOP 10
	st.text,
	qp.query_plan,
	qs.*
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.plan_handle) st
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
ORDER BY total_worker_time DESC
GO


-- Worst performing I/O bound queries
SELECT TOP 10
	st.text,
	qp.query_plan,
	qs.*
	,qp.*
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.plan_handle) st
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
ORDER BY total_logical_reads DESC
GO