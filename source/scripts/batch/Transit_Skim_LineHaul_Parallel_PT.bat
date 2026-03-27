SET workdir=.\outputs\runtime\%2

if exist outputs\skims\Transit_Skims_%2*.err   del outputs\skims\Transit_Skims_%2*.err
if exist outputs\skims\Transit_Skims_%2*.done  del outputs\skims\Transit_Skims_%2*.done
@echo Transit_Skims_%2

if not exist %workdir% mkdir %workdir%
del %workdir%\*.* /f/q
if exist outputs\reports\%_iter_%_TRANSIT_SKIMS_%2*.RPT  del outputs\reports\%_iter_%_TRANSIT_SKIMS_%2*.RPT

:: Spawn the four threads for AM, MD, PM, NT
START ..\source\scripts\batch\Transit_Skim_TOD_Parallel_PT.bat %1 %2 AM %workdir%
START ..\source\scripts\batch\Transit_Skim_TOD_Parallel_PT.bat %1 %2 MD %workdir%
START ..\source\scripts\batch\Transit_Skim_TOD_Parallel_PT.bat %1 %2 PM %workdir%
START ..\source\scripts\batch\Transit_Skim_TOD_Parallel_PT.bat %1 %2 NT %workdir%

:wait
@ECHO OFF
@ping -n 11 127.0.0.1>nul
if exist %workdir%\*.error goto error
if exist %workdir%\*.flag goto wait
@ECHO ON

:: Copy report files
if exist %workdir%\AM\voya*.prn  copy %workdir%\AM\voya*.prn  %workdir%\%_iter_%_TRANSIT_SKIMS_%2_AM.RPT /y
if exist %workdir%\MD\voya*.prn  copy %workdir%\MD\voya*.prn  %workdir%\%_iter_%_TRANSIT_SKIMS_%2_MD.RPT /y
if exist %workdir%\PM\voya*.prn  copy %workdir%\PM\voya*.prn  %workdir%\%_iter_%_TRANSIT_SKIMS_%2_PM.RPT /y
if exist %workdir%\NT\voya*.prn  copy %workdir%\NT\voya*.prn  %workdir%\%_iter_%_TRANSIT_SKIMS_%2_NT.RPT /y

del %workdir%\*\voya*.prn /f/q
copy %workdir%\*.rpt .\outputs\reports\ /y
del %workdir%\*.* /f/q/s
rmdir %workdir% /q

:: The next line can be used to conserve disk space - if uncommented it will delete i1-i3 RTE files
::IF "%_iter_%" NEQ "i4" del outputs\trn_net\*.rte

goto end
:error
echo Error in Transit Skim %2 > outputs\skims\Transit_Skims_%2.err
echo Error in outputs\skims\Transit_Skims_%2
EXIT
:end
echo Finished Transit Skim %2 > outputs\skims\Transit_Skims_%2.done
Exit
