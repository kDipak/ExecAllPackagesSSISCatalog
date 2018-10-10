USE [SSISDB]
GO

/****** Object:  StoredProcedure [dbo].[sp_ExecuteAllPackagesWithinProjectCatalog]    Script Date: 10-10-2018 09:55:00 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




/*********************************************************************************************
Execute All Packages Within SSIS Project Catalog v1.0 (2015-07-06)
(C) 2015, select SIFISO

Feedback: mailto:sifiso@selectsifiso.co.za
Disclaimer: http://www.selectsifiso.net/?page_id=882

License: 
	Execute All Packages Within SSIS Project Catalog is free to download and use for personal, 
	educational, and internal corporate purposes, provided that this header is preserved. 
	Redistribution or sale of Execute All Packages Within SSIS Project Catalog, in whole or 
	in part, is prohibited without the author's express written consent.

Execute Statement: exec [dbo].[sp_ExecAllPackages] @var_foldername = 'SP_Test' , @var_projectname = 'SP_Test', @synchronized = 1, @RetryCounter = 5

*********************************************************************************************/

CREATE  PROC [dbo].sp_ExecAllPackages (

			@var_foldername varchar(100)
			-- SELECT [folder_id] ,[name] FROM [SSISDB].[catalog].[folders]
			
			,@var_projectname varchar(100)
			-- SELECT [project_id],[folder_id],[name] FROM [SSISDB].[catalog].[projects]
			
			,@synchronized bit -- = 1				
			-- WARNING !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			-- 0 is not a problem for small packages and a beefy server. make sure your server can handle this! or else it will eat all your resources
			-- Uncomment to leave the default at 1
			-- set to 0 to execute ALL packages AT ONCE
			-- set to 1 to execute ONE package after the Other, this will wait for the previous packages to finish before executing the next package.

			,@RetryCounter int
			-- In case a package fails, you can set it to retry
) AS

SET NOCOUNT ON;

DECLARE @pkg_name varchar(100), 
		@prj_name varchar(100), 
		@fol_name varchar(100), 
		@message varchar(800),
		@product nvarchar(50),
		@bd datetime,
		@ed datetime,
		@Ref_id bigint;

PRINT ' '
SELECT @message = '***** Executing : ' +  @var_projectname + ' Project, within : ' + @var_foldername + ' Folder *****'
PRINT @message
		
DECLARE sp_execAPWPC_cursor CURSOR FOR 

SELECT 
	pkg.[name] package_name
	,prj.[name] project_name
	,fld.name folder_name    
	,Env.reference_id as Ref_id
FROM [SSISDB].[internal].[packages] pkg
INNER JOIN [SSISDB].[internal].[projects] prj ON pkg.project_id = prj.project_id and prj.[object_version_lsn] = pkg.[project_version_lsn]
INNER JOIN [SSISDB].[internal].[folders] fld ON fld.folder_id = prj.folder_id
LEFT OUTER JOIN  [SSISDB].[dbo].[ExcludePackages] exc ON prj.name = exc.project_name and fld.name = exc.folder_name AND pkg.name = exc.package_name
LEFT OUTER JOIN (
					SELECT  reference_id, environment_folder_name, name
					FROM  SSISDB.[catalog].environment_references er
					JOIN SSISDB.[catalog].projects p ON p.project_id = er.project_id
				) Env ON fld.Name = Env.environment_folder_name AND prj.name = Env.name
WHERE  fld.name = @var_foldername 	AND prj.[name] = @var_projectname AND 
exc.project_name IS NULL

OPEN sp_execAPWPC_cursor

FETCH NEXT FROM sp_execAPWPC_cursor 
INTO @pkg_name, @prj_name, @fol_name, @Ref_id

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT ' '
    SELECT @message = ' - Executing Package : ' +  @pkg_name
	PRINT @message


-- Block for retry if a single package fails
-- retry count is passed through the @retrycounter parameter during runtime.
	DECLARE @retry INT = @RetryCounter
Retry:
PRINT ' - Package executing with : ' + LTRIM(RTRIM(convert(char(5),@retry))) + ' retries left'
	WHILE (@retry > 0)
				--IF( @@TRANCOUNT = 0 )
	BEGIN
-- retry block 

				Declare @execution_id bigint
				EXEC [SSISDB].[catalog].[create_execution]		@package_name=@pkg_name, @execution_id=@execution_id 
														OUTPUT, @folder_name=@fol_name, @project_name=@prj_name, @use32bitruntime=False, @reference_id=@Ref_id
				Select @execution_id
				DECLARE @var0 smallint = 1
				EXEC [SSISDB].[catalog].[set_execution_parameter_value] @execution_id,  @object_type=50, @parameter_name=N'LOGGING_LEVEL', @parameter_value=@var0
	
				-- You can specify this parameter when executing the Stored Procedure, 
				-- set to 0 to execute ALL packages AT ONCE
				-- set to 1 to execute ONE package after the Other, this will wait for the previous packages to finish before executing the next package.
				EXEC [SSISDB].[catalog].[set_execution_parameter_value] @execution_id, @object_type=50, @parameter_name=N'SYNCHRONIZED', @parameter_value=@synchronized
	
				SET @bd = Getdate()
				EXEC [SSISDB].[catalog].[start_execution] @execution_id
				SET @ed = Getdate()

				IF 7 <> (SELECT [status] FROM [SSISDB].[catalog].[executions] WHERE execution_id = @execution_id)
				RAISERROR('The package failed. Check the SSIS catalog logs for more information', 16, 1)
				
				-- custom SQL statemwent error to call the particular error messages related to this execution
				IF 7 <> (SELECT [status] FROM [SSISDB].[catalog].[executions] WHERE execution_id = @execution_id) 
				PRINT '
				
				Execute the following SQL Statement to get the error message related to this execution
				
						SELECT [operation_id] ,[message_time] ,[message]
						FROM [SSISDB].[catalog].[operation_messages]
						WHERE message_type = 120 and operation_id = ' + convert(char(5),@execution_id ) + '
						
						Error Generated: '+ convert(char(50), Getdate()) + '
						
						'
						
				IF 7 = (SELECT [status] FROM [SSISDB].[catalog].[executions] WHERE execution_id = @execution_id)
				
-- Break the while loop if package runs succesfully.
				BREAK 

				SELECT @message = ' - Package Duration : ' + CONVERT(nvarchar(10),DATEDIFF(SECOND,@bd, @ed)) + ' Seconds'
						
				PRINT @message
				PRINT ' '

-- retry block countdown
				SET @retry -=1

-- retry block go to begining of block
GOTO Retry

END


    FETCH NEXT FROM sp_execAPWPC_cursor 
    INTO @pkg_name, @prj_name, @fol_name, @Ref_id
END 
CLOSE sp_execAPWPC_cursor;
DEALLOCATE sp_execAPWPC_cursor;
GO


