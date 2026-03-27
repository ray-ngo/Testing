:: 2018-03-30 RN Add lines to execute a check on whether transit stations are accessible

:: FXIE 02-23-2021  This batch file is modified to generate additional skims in support
::                  of Gen3 Model development, including:
::                  1) Highway skims for 4 time-of-day periods instead of 2
::                  2) Calculate intra-zonal distances and include them in distance skims
::                     Intrazonal_dist = Factor * mean (distance to K nearest zones)
::					   Where Factor is typically 0.5 and K is 3 or 4. (we chose 4)
::                  3) Build shortest-distance paths and generate walk/bike skims on them
::                     Assumed walking speed = 3 mph
::                     Assumed cycling speed =10 mph

set _iterOrder_=initial

REM  Highway Skims

:: COPY ZONEHWY.NET TEMPORARILY TO PPHWY.NET

if exist outputs\hwy_net\ZONEHWY.NET  COPY outputs\hwy_net\ZONEHWY.NET outputs\hwy_net\PP_HWY.NET /y

if exist voya*.*  del voya*.*
if exist outputs\reports\%_iter_%_%_iterOrder_%_Highway_Skims_4TOD.rpt  del outputs\reports\%_iter_%_%_iterOrder_%_Highway_Skims_4TOD.rpt
start /w Voyager.exe  ..\source\scripts\cube\Highway_Skims_4TOD.s /start -Pvoya -S..\%1
if errorlevel 2 goto error
if exist voya*.prn  copy voya*.prn outputs\reports\%_iter_%_%_iterOrder_%_Highway_Skims_4TOD.rpt /y

ping -n 11 127.0.0.1 > nul


:: ----- Save initial highway skims to special names for later checking

if exist outputs\skims\pp_am_SOV.SKM   copy outputs\skims\pp_am_SOV.SKM     outputs\skims\pp_am_SOV_Initial.SKM /y
if exist outputs\skims\pp_md_SOV.SKM   copy outputs\skims\pp_md_SOV.SKM     outputs\skims\pp_md_SOV_Initial.SKM /y
if exist outputs\skims\pp_pm_SOV.SKM   copy outputs\skims\pp_pm_SOV.SKM     outputs\skims\pp_pm_SOV_Initial.SKM /y
if exist outputs\skims\pp_nt_SOV.SKM   copy outputs\skims\pp_nt_SOV.SKM     outputs\skims\pp_nt_SOV_Initial.SKM /y
if exist outputs\skims\pp_am_HOV2.SKM  copy outputs\skims\pp_am_HOV2.SKM    outputs\skims\pp_am_HOV2_Initial.SKM /y
if exist outputs\skims\pp_md_HOV2.SKM  copy outputs\skims\pp_md_HOV2.SKM    outputs\skims\pp_md_HOV2_Initial.SKM /y
if exist outputs\skims\pp_pm_HOV2.SKM  copy outputs\skims\pp_pm_HOV2.SKM    outputs\skims\pp_pm_HOV2_Initial.SKM /y
if exist outputs\skims\pp_nt_HOV2.SKM  copy outputs\skims\pp_nt_HOV2.SKM    outputs\skims\pp_nt_HOV2_Initial.SKM /y
if exist outputs\skims\pp_am_HOV3.SKM  copy outputs\skims\pp_am_HOV3.SKM    outputs\skims\pp_am_HOV3_Initial.SKM /y
if exist outputs\skims\pp_md_HOV3.SKM  copy outputs\skims\pp_md_HOV3.SKM    outputs\skims\pp_md_HOV3_Initial.SKM /y
if exist outputs\skims\pp_pm_HOV3.SKM  copy outputs\skims\pp_pm_HOV3.SKM    outputs\skims\pp_pm_HOV3_Initial.SKM /y
if exist outputs\skims\pp_nt_HOV3.SKM  copy outputs\skims\pp_nt_HOV3.SKM    outputs\skims\pp_nt_HOV3_Initial.SKM /y

::  ----- the PP_??.SKM files will be overwritten after the skimming
::  ----- of the PP Highway assignment network


:: DELETE TEMPORARY ppHWY.NET, THIS WILL BE CREATED AFTER the PP HIGHWAY ASSIGNMENT

rem if exist PP_HWY.NET del PP_HWY.NET


if exist voya*.*  del voya*.*
if exist outputs\reports\%_iter_%_%_iterOrder_%_Remove_PP_Speed.rpt  del outputs\reports\%_iter_%_%_iterOrder_%_Remove_PP_Speed.rpt
start /w Voyager.exe  ..\source\scripts\cube\Remove_PP_Speed.s /start -Pvoya -S..\%1
if errorlevel 1 goto error
if exist voya*.prn  copy voya*.prn outputs\reports\%_iter_%_%_iterOrder_%_Remove_PP_Speed.rpt /y



:: FXIE 2/23/2021, prepare non-motorized (walk/bike) distance/skim
:: Executed once and only once


if exist voya*.*  del voya*.*
if exist outputs\reports\Prepare_non_motorized_skims.rpt  del outputs\reports\Prepare_non_motorized_skims.rpt
start /w Voyager.exe  ..\source\scripts\cube\Prepare_Non_Motorized_Skims.s /start -Pvoya -S..\%1
if errorlevel 1 goto error
if exist voya*.prn  copy voya*.prn outputs\reports\Prepare_non_motorized_skims.rpt /y

goto end

:stationerr
PAUSE&EXIT

:error
REM  Processing Error....
ECHO Error in PP Highway Skims
SET ERROR_FLAG=1
EXIT
:end
set _iterOrder_=
