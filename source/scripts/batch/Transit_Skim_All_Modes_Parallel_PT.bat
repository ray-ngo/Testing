::  Transit Skimming for All Submodes
::  updated 4/27/07  copy sta_tpp.bse from inputs to output subdir.
::  updated 6/15/11  runs walkacc process for pp iteration only
::  updated 5/11/16  Update autoacc and local-bus in-vehicle speed degradation
::  updated 2/19/20 for PT-based Skimming Process
::---------------------------------------------
::  Version 2.3 Transit SKIM and Fare2 Process
::---------------------------------------------

::develop PT network building process to include updating the transit speeds
:: (Added 4/24/19)
if exist voya*.*  del voya*.*
if exist outputs\reports\V2.5_PTNet_Build_Iteration.rpt  del outputs\reports\V2.5_PTNet_Build_Iteration.rpt
start /w Voyager.exe  ..\source\scripts\cube\V2.5_PTNet_Build_Iteration.S /start -Pvoya -S..\%1
if errorlevel 2 goto error
if exist voya*.prn  copy voya*.prn outputs\reports\V2.5_PTNet_Build_Iteration.rpt /y
::

if exist voya*.*  del voya*.*
if exist outputs\reports\PT_NetProcess_PT.rpt  del outputs\reports\PT_NetProcess_PT.rpt
start /w Voyager.exe  ..\source\scripts\cube\PT_NetProcess_PT.s /start -Pvoya -S..\%1
if errorlevel 2 goto error
if exist voya*.prn  copy voya*.prn outputs\reports\PT_NetProcess_PT.rpt /y

:: =======================================
:: = Transit Skimming Section            =
:: =======================================

::  Transit Network Building (Final) Commuter Rail
:Parallel_Processing
ECHO Start Transit Skim - Parallel

IF NOT EXIST .\outputs\runtime MKDIR .\outputs\runtime

START ..\source\scripts\batch\Transit_Skim_LineHaul_Parallel_PT.bat %1 CR

REM  Transit Network Building (Final) Metrorail
START ..\source\scripts\batch\Transit_Skim_LineHaul_Parallel_PT.bat %1 MR

REM  Transit Network Building (Final) All Bus
START ..\source\scripts\batch\Transit_Skim_LineHaul_Parallel_PT.bat %1 AB

REM  Transit Network Building (Final) Bus+MetroRail
START ..\source\scripts\batch\Transit_Skim_LineHaul_Parallel_PT.bat %1 BM

@ECHO OFF

:waitForMC
@ping -n 11 127.0.0.1>nul

:Transit_Skims_Are_Done

@REM Check file existence to ensure that there are no errors
IF EXIST outputs\skims\Transit_Skims_CR.err ECHO Error in outputs\skims\Transit_Skims_CR && GOTO fastFail
IF EXIST outputs\skims\Transit_Skims_MR.err ECHO Error in outputs\skims\Transit_Skims_MR && GOTO fastFail
IF EXIST outputs\skims\Transit_Skims_AB.err ECHO Error in outputs\skims\Transit_Skims_AB && GOTO fastFail
IF EXIST outputs\skims\Transit_Skims_BM.err ECHO Error in outputs\skims\Transit_Skims_BM && GOTO fastFail

@REM Check to ensure that each of the batch processes have finished successfully, if not wait.
if not exist outputs\skims\Transit_Skims_CR.done GOTO waitForMC
if not exist outputs\skims\Transit_Skims_MR.done GOTO waitForMC
if not exist outputs\skims\Transit_Skims_AB.done GOTO waitForMC
if not exist outputs\skims\Transit_Skims_BM.done GOTO waitForMC

@ECHO ON

REM ****************************************************
REM * Temporary? Code                                  *
REM *                                                  *
REM * This deletes the transit RTE outputs, which are  *
REM * not used beyond this and are extremely large     *
REM * under Cube 6.5 (around 85 GB).                   *
REM ****************************************************

REM IF %_iter_% NEQ i4 ECHO Would delete route files
::DEL outputs\trn_net\*.RTE

REM @type CR.txt
REM @type MR.txt
REM @type AB.txt
REM @type BM.txt

:: if exist voya*.*  del voya*.*
:: if exist MFare2_PT.rpt  del MFare2_PT.rpt
:: start /w Voyager.exe  ..\scripts\MFare2_PT.s /start -Pvoya -S..\%1
:: if errorlevel 2 goto error
:: if exist voya*.prn  copy voya*.prn MFare2_PT.rpt /y

:: commented by bmp
::if exist voya*.*  del voya*.*
::if exist Post_Skim_PT.rpt  del Post_Skim_PT.rpt
::start /w Voyager.exe  ..\scripts\Post_Skim_PT.s /start -Pvoya -S..\%1
::if errorlevel 2 goto error
::if exist voya*.prn  copy voya*.prn Post_Skim_PT.rpt /y
::
::if exist voya*.*  del voya*.*
::if exist %_iter_%_TRANSIT_Accessibility.RPT  del %_iter_%_TRANSIT_Accessibility.RPT
::start /w Voyager.exe  ..\scripts\transit_Accessibility.s /start -Pvoya -S..\%1
::if errorlevel 2 goto error
::if exist voya*.prn  copy voya*.prn %_iter_%_TRANSIT_Accessibility.RPT /y

GOTO end


:fastFail
@ECHO ON
TIMEOUT 10 /NOBREAK >NUL
TASKKILL /F /IM Voyager.exe >NUL

:error
REM  Processing Error......
ECHO Error in Transit Skimming
SET ERROR_FLAG=1
EXIT /b
:end
