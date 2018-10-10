
Execute All Packages Within SSIS Project Catalog V 2.0 (sp_ExecAllPackages)

This stored procedure has been modified and extended with several options
- Ability to run packages in Parallel or Async mode
- Retry Failed packages
- Exclusion list - view
- Custom Error messages

Execute Statement: 
 ```  
    exec [dbo].[sp_ExecAllPackages] 
          @var_foldername = 'SP_Test' , 
          @var_projectname = 'SP_Test',
          @synchronized = 1, 
          @RetryCounter = 5```


Credits to the original creator:
```
Execute All Packages Within SSIS Project Catalog V 1.0

Execute All Packages Within SSIS Project Catalog v1.0 (2015-07-06) (C) 2015, select SIFISO
Feedback: mailto:sifiso@selectsifiso.co.za
Disclaimer: http://www.selectsifiso.net/?page_id=882

License:
Execute All Packages Within SSIS Project Catalog is free to download and use for personal, 
educational, and internal corporate purposes, provided that this header is preserved. 
Redistribution or sale of Execute All Packages Within SSIS Project Catalog, in whole or 
in part, is prohibited without the author's express written consent.
```
