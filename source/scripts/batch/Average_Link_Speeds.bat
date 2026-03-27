REM  Average Link Speeds

:: Write loaded links file from assignment to new file
:: current iteration speeds will be removed and rewritten with averaged speeds below
:: 03/22/2019 RN  Modified lines 8, 9, 21  to address the potential issue of using iter_HWY.NET incorrectly
if exist outputs\hwy_net\temp1_%_iter_%_HWY.net   copy   outputs\hwy_net\temp1_%_iter_%_HWY.net    outputs\hwy_net\%_iter_%_Assign_Output.net /y
if exist outputs\hwy_net\temp1_%_iter_%_HWY.net   copy   outputs\hwy_net\temp1_%_iter_%_HWY.net    outputs\hwy_net\%_iter_%_HWY.tem1 /y


if exist voya*.*  del voya*.*
if exist outputs\reports\%_iter_%_Average_Link_Speeds.rpt  del  outputs\reports\%_iter_%_Average_Link_Speeds.rpt
start /w Voyager.exe  ..\source\scripts\cube\Average_Link_Speeds.s /start -Pvoya -S..\%1
if errorlevel 1 goto error
if exist voya*.prn  copy voya*.prn outputs\reports\%_iter_%_Average_Link_Speeds.rpt /y

:: Now copy over the original Loaded file with revised file containing new/avg speeds
:: Note: the original file from assignment is maintained as %_iter_%_Assigned_%HWY.net

if exist  outputs\hwy_net\%_iter_%_Averaged_HWY.net  copy outputs\hwy_net\%_iter_%_Averaged_HWY.net outputs\hwy_net\temp2_%_iter_%_HWY.net /y


goto end
:error
REM  Processing Error....
ECHO There was an error in Average Link Speeds
SET ERROR_FLAG=1
:end
