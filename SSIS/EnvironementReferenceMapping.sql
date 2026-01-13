--Author: Martin Tydor
--
--Description:
--Select evironment reference mapping


select r.reference_id, r.environment_name, p.name as Projectname from ssisdb.catalog.environment_references as r 
inner join ssisdb.catalog.projects as p on r.project_id = p.project_id