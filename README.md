
Execute All Packages Within SSIS Project Catalog V 2.0 (sp_ExecAllPackages)

This stored procedure has been modified and extended with several options
- Ability to run packages in Parallel or Async mode
- Retry Failed packages
- Exclusion list - view
- Custom Error messages

###### Execute Statement: 
 ```  
    exec [dbo].[sp_ExecAllPackages] 
          @var_foldername = 'SP_Test' , 
          @var_projectname = 'SP_Test',
          @synchronized = 1, 
          @RetryCounter = 5
          ```
