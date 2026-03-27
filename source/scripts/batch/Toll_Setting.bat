SET MAXTGRPS=1000

IF EXIST TOLL_SETTING del TOLL_SETTING /s /q
md TOLL_SETTING
md TOLL_SETTING\AM
md TOLL_SETTING\MD
md TOLL_SETTING\PM
md TOLL_SETTING\FINAL_TOLL

CD TOLL_SETTING

copy ..\outputs\reports\HWY_Deflator.txt AM\HWY_Deflator.txt /y
copy ..\outputs\reports\HWY_Deflator.txt MD\HWY_Deflator.txt /y
copy ..\outputs\reports\HWY_Deflator.txt PM\HWY_Deflator.txt /y

copy ..\outputs\hwy_net\I4_assign_output.NET AM\I4_assign_output.net /y
copy ..\outputs\hwy_net\I4_assign_output.NET MD\I4_assign_output.net /y
copy ..\outputs\hwy_net\I4_assign_output.NET PM\I4_assign_output.net /y

copy ..\outputs\hwy_assign\I4_AM.VTT  AM\I4_AM.VTT /y
copy ..\outputs\hwy_assign\I4_MD.VTT  MD\I4_MD.VTT /y
copy ..\outputs\hwy_assign\I4_PM.VTT  PM\I4_PM.VTT /y


:: Do MD first
START /w %BATCH_DIR%\%TOLL_SETTING_MD_BAT%
if exist *.error goto error

:: Process AM and PM in parallel
if %cubeversion% EQU 25.00.01 (
   TASKKILL /IM ClusterManager.exe /F 2>NUL
)

START %BATCH_DIR%\%TOLL_SETTING_AM_BAT%
START %BATCH_DIR%\%TOLL_SETTING_PM_BAT%

@ECHO OFF
:wait
@ping -n 11 127.0.0.1>nul
if exist *.error goto fastFail
if exist *.flag goto wait

@ECHO ON
if exist *.error goto error

for /f %%a in ('dir AM\OUT*.TXT /B /O:-D') do (set AMTOLL=%%a
goto amstop)
:amstop

for /f %%a in ('dir MD\OUT*.TXT /B /O:-D') do (set MDTOLL=%%a
goto mdstop)
:mdstop

for /f %%a in ('dir PM\OUT*.TXT /B /O:-D') do (set PMTOLL=%%a
goto pmstop)
:pmstop

echo The final toll files are %AMTOLL%, %MDTOLL%, and %PMTOLL%.

CD FINAL_TOLL

start /w Voyager.exe  %ROOT_DIRECTORY%/source/scripts/cube/Post_Toll_Search.s /start -Pvoya -S./
if errorlevel 2 goto error

if exist ..\..\inputs\hwy\toll_esc_base.dbf del ..\..\inputs\hwy\toll_esc_base.dbf
ren ..\..\inputs\hwy\toll_esc.dbf toll_esc_base.dbf
copy Final_Toll_Esc.dbf ..\..\inputs\hwy\toll_esc.dbf

CD..
CD..

:: After successfully conducting toll searching, copy the full log and delete all files under \Outputs
copy outputs\reports\%scenar%_fulloutput.txt %scenar%_TS_fulloutput.txt
del /S /Q /F "outputs\*.*" >NUL

goto end

:fastFail
@ECHO ON
:: Make sure all Voyager processes have started before calling taskkill
TIMEOUT 10 /NOBREAK >NUL
TASKKILL /F /IM Voyager.exe >NUL

:error
ECHO Error in Toll Setting
SET ERROR_FLAG=1

:end
if %cubeversion% EQU 25.00.01 (
   TASKKILL /IM ClusterManager.exe /F 2>NUL
)
