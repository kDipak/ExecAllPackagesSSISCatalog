USE [selectSIFISOBlogs]
GO

/****** Object:  StoredProcedure [dbo].[sp_ExecuteAllPackagesWithinProjectCatalog]    Script Date: 2015-07-06 04:08:04 PM ******/
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

Test: EXEC [dbo].[sp_ExecuteAllPackagesWithinProjectCatalog] 'Encashments','EncashmentStaging'
*********************************************************************************************/
create PROC [dbo].[sp_ExecuteAllPackagesWithinProjectCatalog] (
	@var_foldername varchar(100)
	,@var_projectname varchar(100)
) AS

SET NOCOUNT ON;

DECLARE @pkg_name varchar(100), 
		@prj_name varchar(100), 
		@fol_name varchar(100), 
		@message varchar(800),
		@product nvarchar(50);

PRINT ' '
SELECT @message = '***** Executing : ' +  @var_projectname + ' Project, within : ' + @var_foldername + ' Folder *****'
PRINT @message
		
DECLARE sp_execAPWPC_cursor CURSOR FOR 

SELECT 
	pkg.[name] package_name
	,prj.[name] project_name
	,fld.name folder_name    
FROM [SSISDB].[internal].[packages] pkg
INNER JOIN [SSISDB].[internal].[projects] prj
	ON pkg.project_id = prj.project_id
	and prj.[object_version_lsn] = pkg.[project_version_lsn]
INNER JOIN [SSISDB].[internal].[folders] fld
	ON fld.folder_id = prj.folder_id
WHERE  fld.name = @var_foldername 
	AND prj.[name] = @var_projectname

OPEN sp_execAPWPC_cursor

FETCH NEXT FROM sp_execAPWPC_cursor 
INTO @pkg_name, @prj_name, @fol_name

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT ' '
    SELECT @message = '----- Executing Package : ' +  @pkg_name

    PRINT @message

	Declare @execution_id bigint
	EXEC [SSISDB].[catalog].[create_execution] @package_name=@pkg_name, @execution_id=@execution_id OUTPUT, @folder_name=@fol_name, @project_name=@prj_name, @use32bitruntime=False, @reference_id=Null
	Select @execution_id
	DECLARE @var0 smallint = 1
	EXEC [SSISDB].[catalog].[set_execution_parameter_value] @execution_id,  @object_type=50, @parameter_name=N'LOGGING_LEVEL', @parameter_value=@var0
	EXEC [SSISDB].[catalog].[start_execution] @execution_id
	

    FETCH NEXT FROM sp_execAPWPC_cursor 
    INTO @pkg_name, @prj_name, @fol_name
END 
CLOSE sp_execAPWPC_cursor;
DEALLOCATE sp_execAPWPC_cursor;


GO

