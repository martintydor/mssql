--Author: Martin Tydor
--
--Description:
--Returns a single row describing the configuration of the job object that manages the SQL Server process

SELECT cpu_rate,
    cpu_affinity_mask,
    process_memory_limit_mb,
    non_sos_mem_gap_mb
FROM sys.dm_os_job_object;