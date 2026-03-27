REM  05/10/2019 RN Add subnodes for PM and NT Highway Assignment

if exist voya*.*  del voya*.*
if exist outputs\reports\%_iter_%_Highway_Assignment.rpt   del outputs\reports\%_iter_%_Highway_Assignment.rpt

Cluster.exe AM %AMsubnode% start exit
Cluster.exe MD %MDsubnode% start exit
Cluster.exe PM %PMsubnode% start exit
Cluster.exe NT %NTsubnode% start exit
start /w Voyager.exe ..\source\scripts\cube\Highway_Assignment_Parallel_Cube6.s  /start -Pvoya -S..\%1
if errorlevel 2 goto error ; Moved from below Cluster + Changed to 2 (due to crash on Cube 6.4.1)
Cluster.exe AM %AMsubnode% close exit
Cluster.exe MD %MDsubnode% close exit
Cluster.exe PM %PMsubnode% close exit
Cluster.exe NT %NTsubnode% close exit

copy Voya*.prn       outputs\reports\%_iter_%_Highway_Assignment.rpt /y

ECHO Highway assignment completed successfully.
goto end
:error
ECHO Error in Highway Assignment
SET ERROR_FLAG=1


:end
