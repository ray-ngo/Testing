REM  Highway Skims

:: RQN 02-04-2019   Add two lines 8-9 to fix a bug of the model using <ITER>_HWY.net
::                  incorrectly when the model crash at a certain step

:: FXIE 02-23-2021  This batch file is modified to generate additional skims in support
::                  of Gen3 Model development, including:
::                  1) Highway skims for 4 time-of-day periods instead of 2
::                  2) Calculate intra-zonal distances and include them in distance skims
::                     Intrazonal_dist = Factor * mean (distance to K nearest zones)
::					   Where Factor is typically 0.5 and K is 3 or 4. (we chose 4)


if exist outputs\hwy_net\temp1_%_iter_%_HWY.net copy outputs\hwy_net\temp1_%_iter_%_HWY.net outputs\hwy_net\%_iter_%_HWY.net
if exist outputs\hwy_net\temp2_%_iter_%_HWY.net copy outputs\hwy_net\temp2_%_iter_%_HWY.net outputs\hwy_net\%_iter_%_HWY.net

if exist voya*.*  del voya*.*
if exist outputs\reports\%_iter_%_Highway_Skims_4TOD.rpt  del outputs\reports\%_iter_%_Highway_Skims_4TOD.rpt
start /w Voyager.exe  ..\source\scripts\cube\Highway_Skims_4TOD.s /start -Pvoya -S..\%1
if errorlevel 2 goto error
if exist voya*.prn  copy voya*.prn outputs\reports\%_iter_%_Highway_Skims_4TOD.rpt /y


goto end
:error
REM  Processing Error....
ECHO Error in Highway Skims
SET ERROR_FLAG=1
:end
