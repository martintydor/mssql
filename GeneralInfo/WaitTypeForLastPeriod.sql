--Author: Martin Tydor
--
--Description:
--Returns waits accumulated value for the last period of days (7)

SELECT ws.wait_category_desc, sum(total_query_wait_time_ms) as WaitValue
	FROM sys.query_store_plan AS p
	JOIN sys.query_store_wait_stats AS ws
	ON ws.plan_id = p.plan_id
	WHERE 
	p.plan_id in 
		(select plan_id from sys.query_store_runtime_stats where last_execution_time > DATEADD(day, -7, getdate()))
	GROUP BY wait_category_desc
	order by WaitValue desc
    