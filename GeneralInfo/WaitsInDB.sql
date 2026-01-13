--Author: Martin Tydor
--
--Description:
--Script retuns cummulated waits numbers for DB

select * from sys.dm_os_wait_stats
where wait_type not in ('SOS_WORK_DISPATCHER','PREEMPTIVE_XE_DISPATCHER')
order by wait_time_ms desc
