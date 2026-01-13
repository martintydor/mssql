--Author: Martin Tydor
--
--Description:
--Script parameter mapping in SSIS environment



USE SSISDB
GO
 
WITH mapping AS (   
SELECT isnull (er.environment_folder_name, f.name) environment_folder_name,
       er.environment_name,
       p.name AS Project_Name,
       er.reference_type,
       ev.variable_id,
       ev.name AS Environment_Variable_Name,
       ev.sensitive ev_sensitive,
       ev.type,
       ev.value,
       op.parameter_id,
       op.object_type,
       op.object_name,
       op.parameter_name,
       op.data_type AS Parameter_Data_Type,
       op.required,
       op.sensitive op_sensitive,
       op.default_value,
       op.design_default_value,
       op.value_set,
       op.value_type
FROM catalog.environment_references er
    INNER JOIN catalog.projects p
        ON er.project_id = p.project_id
	LEFT JOIN catalog.folders f on p.folder_id = f.folder_id
    INNER JOIN catalog.environments e
        ON er.environment_name = er.environment_name
    INNER JOIN catalog.environment_variables ev
        ON e.environment_id = ev.environment_id
    INNER JOIN catalog.object_parameters op
        ON op.project_id = p.project_id
           AND op.value_type = N'R'
           AND op.referenced_variable_name = ev.name
)
 
SELECT DISTINCT 
environment_folder_name,
Project_Name,
OBJECT_NAME,
parameter_name,
Environment_Variable_Name,
Script = 'EXEC [SSISDB].[catalog].[set_object_parameter_value]
        @object_type=20 
      , @parameter_name= N''' + isnull (CONVERT(NVARCHAR(500), parameter_name),'') + '''
      , @object_name= N''' + isnull (OBJECT_NAME ,'')+ '''   
      , @folder_name= N''' + isnull (environment_folder_name,'UKIWMS') + '''
      , @project_name= N''' + Project_Name + '''
      , @value_type= R
      , @parameter_value= N''' + CONVERT(NVARCHAR(500), Environment_Variable_Name) + ''';
'
from mapping