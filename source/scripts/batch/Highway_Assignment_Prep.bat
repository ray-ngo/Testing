REM -----------------------------------------
REM  Prepare trips for highway assignment
REM -----------------------------------------

if exist voya*.*  del voya*.*
if exist outputs\reports\%_iter_%_Prepare_Trip_Tables_for_Assignment.rpt   del outputs\reports\%_iter_%_Prepare_Trip_Tables_for_Assignment.rpt
start /w Voyager.exe  ..\source\scripts\cube\Prepare_Trip_Tables_for_Assignment.s /start -Pvoya -S..\%1
if errorlevel 1 goto error
copy voya*.prn            outputs\reports\%_iter_%_Prepare_Trip_Tables_for_Assignment.rpt /y

goto end

:error
ECHO Processing Error in Highway Assignment Prep
SET ERROR_FLAG=1

EXIT
:end
ECHO Highway Assignment Prep Completed.
