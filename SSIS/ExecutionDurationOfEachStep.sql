with a as (
select   m.event_message_id event_message_id,m.operation_id execution_id, 
		 m.package_name, m.message_source_name source_name, 
		cast (m.message_time as datetime) m_time,left (m.[execution_path],4000) as [execution_path],m.[subcomponent_name],
		[message_type] = CASE m.[message_type]
			 when -1 then 'Unknown'
			 when 120 then 'Error'
			 when 110 then 'Warning'
			 when 70 then 'Information'
			 when 10 then 'Pre-validate'
			 when 20 then 'Post-validate'
			 when 30 then 'Pre-execute'
			 when 40 then 'Post-execute'
			 when 60 then 'Progress'
			 when 50 then 'StatusChange'
			 when 100 then 'QueryCancel'
			 when 130 then 'TaskFailed'
			 when 90 then 'Diagnostic'
			 when 200 then 'Custom'
			 when 140 then 'DiagnosticEx'
		END,
		cast(m.message as varchar(2000)) message
		
	 from SSISDB.catalog.event_messages m  WITH(NOLOCK) 
	 left join (select event_message_id,[m_time] from  ssis.DWH_SSIS_ALLMESSAGES  WITH(NOLOCK) ) as n   on m.event_message_id = n.event_message_id and cast (m.message_time as datetime)= n.[m_time]
	
	 where m.operation_id=156748
	 and [message_type] in (30,40)
)
select f.execution_path, f.m_time as starttime, s.m_time as endtime, DATEDIFF(second, f.m_time, s.m_time) as Duration
from a as f
inner join a as s on f.execution_path = s.execution_path and s.message_type='Post-execute'
where f.message_type = 'Pre-execute'
order by starttime
