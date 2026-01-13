--Author: Tibor Burda
--
--Description:
--Get information abou geo replication between every single primary and secondary database link.
SELECT   
     link_guid  
   , partner_server 
   , partner_database
   , last_replication  
   , replication_lag_sec   
FROM sys.dm_geo_replication_link_status;