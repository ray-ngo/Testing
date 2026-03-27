if exist voya*.*  del voya*.*
if exist outputs\reports\%_iter_%_Highway_Assignment.rpt   del outputs\reports\%_iter_%_Highway_Assignment.rpt

taskkill /im ClusterManager.exe /f 2>NUL
"c:\Program Files\Bentley\OpenPaths\CUBE %cubeversion%\Voyager\VoyagerCLI.exe" ..\source\scripts\cube\Highway_Assignment_Parallel_Cube25.s -P voya -S ..\%1

if errorlevel 2 goto error ; Moved from below Cluster + Changed to 2 (due to crash on Cube 6.4.1)

copy Voya*.prn       outputs\reports\%_iter_%_Highway_Assignment.rpt /y

ECHO Highway assignment completed successfully.
goto end
:error
ECHO Error in Highway Assignment
SET ERROR_FLAG=1


:end
taskkill /im ClusterManager.exe /f 2>NUL
