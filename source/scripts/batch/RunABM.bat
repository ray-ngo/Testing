@ECHO OFF
ECHO %startTime%%Time%

::~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
:: Run ActivitySim and associated scripts
::~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

:: user specified for now; once model is stable, automatically calculate many of these
SET SCEN_NAME=%1
SET SCEN_DIRECTORY=%2
ECHO SCEN_DIRECTORY: %SCEN_DIRECTORY%

ECHO ROOT_DIRECTORY: %ROOT_DIRECTORY%

ECHO ASIM_CFG_ROOT_DIR: %ASIM_CFG_ROOT_DIR%

SET PYTHON_SCRIPTS_DIR=%ROOT_DIRECTORY%\source\scripts\python

SET SAMPLE_HH1=250000
SET SAMPLE_HH2=500000
SET SAMPLE_HH3=1000000
:: 20% run for initial calibration
REM SET SAMPLE_HH4=558071
SET SAMPLE_HH4=0

SET "check_cube_errors=IF ERRORLEVEL 2 GOTO CUBEERROR"
SET "check_python_errors=IF ERRORLEVEL 1 GOTO PYERROR"
SET "check_asim_errors=IF ERRORLEVEL 1 GOTO ASIMERROR"

:: -------------------------------------------------------------------------------------------------
:: Clean Output Folder
:: -------------------------------------------------------------------------------------------------

IF EXIST "%SCEN_DIRECTORY%\outputs\activitysim\final_*.csv" DEL "%SCEN_DIRECTORY%\outputs\activitysim\final_*.csv"
IF EXIST "%SCEN_DIRECTORY%\outputs\activitysim\*trips*.omx" DEL "%SCEN_DIRECTORY%\outputs\activitysim\*trips*.omx"
IF EXIST "%SCEN_DIRECTORY%\outputs\skims\OMX_Skims\skims.omx" DEL "%SCEN_DIRECTORY%\outputs\skims\OMX_Skims\skims.omx"

:: -------------------------------------------------------------------------------------------------
:: Loop
:: -------------------------------------------------------------------------------------------------
ECHO ****MODEL ITERATION %_iter_%

:: Default chunk training mode
SET CHUNK_TRAINING_MODE=disabled

IF %_iter_% EQU i1 SET SAMPLE=%SAMPLE_HH1%
IF %_iter_% EQU i2 SET SAMPLE=%SAMPLE_HH2%
IF %_iter_% EQU i3 SET SAMPLE=%SAMPLE_HH3%
IF %_iter_% EQU i4 SET SAMPLE=%SAMPLE_HH4%

:: Set chunk training mode to explicit if households are 0 or > 500k
IF %SAMPLE% EQU 0 SET CHUNK_TRAINING_MODE=explicit
IF %SAMPLE% GTR 500000 SET CHUNK_TRAINING_MODE=explicit

ECHO CURRENT DIRECTORY: %cd%

CD %ASIM_CFG_ROOT_DIR%

:: Set sample_rate in configs file dynamically
ECHO Configs File with Sample Rate set by Model Runner

CD configs_mp
COPY /y settings_source.yaml settings.yaml
%PYTHON% %PYTHON_SCRIPTS_DIR%\rewrite_source_file_with_user_define_values.py settings.yaml %%sample_size%% %SAMPLE% %%training_mode%% %CHUNK_TRAINING_MODE% %%num_processes%% %ASIM_NUM_PROCESSES%

ECHO Adding model year to vehicle type choice model

IF %_iter_% EQU i1 (
CD ..\configs
COPY /y vehicle_type_choice_source.yaml vehicle_type_choice.yaml
%PYTHON% %PYTHON_SCRIPTS_DIR%\rewrite_source_file_with_user_define_values.py vehicle_type_choice.yaml %%fleet_year%% %_fleetyear_%

)

CD %SCEN_DIRECTORY%

:: -------------------------------------------------------------------------------------------------
:: Run MWCOG ActivitySim
:: -------------------------------------------------------------------------------------------------

:: setup paths to Python application and other libraries in the gen3_model_uv environment.
ECHO PYTHON: %PYTHON%

:: Set other activitysim environment variables
set MKL_NUM_THREADS=1
set NUMBA_NUM_THREADS=1
set OMP_NUM_THREADS=1
set OPENBLAS_NUM_THREADS=1

CD /d %SCEN_DIRECTORY%

:: Landuse Processing
ECHO Processing landuse data ...
ECHO %startTime%%Time%

%PYTHON% %PYTHON_SCRIPTS_DIR%\landuse_processing.py %SCEN_DIRECTORY%
%check_python_errors%
ECHO %startTime%%Time%
ECHO Landuse data processing complete!

:: Cube to OMX skims
ECHO Converting skims to omx ...
ECHO %startTime%%Time%

IF NOT EXIST %SCEN_DIRECTORY%\outputs\skims\OMX_Skims MD %SCEN_DIRECTORY%\outputs\skims\OMX_Skims
IF NOT EXIST %SCEN_DIRECTORY%\outputs\runtime MD %SCEN_DIRECTORY%\outputs\runtime
IF NOT EXIST %SCEN_DIRECTORY%\outputs\runtime\skm_to_omx MD %SCEN_DIRECTORY%\outputs\runtime\skm_to_omx
DEL %SCEN_DIRECTORY%\outputs\runtime\skm_to_omx\* /q

START ..\source\scripts\batch\skm_to_omx.bat %1 AM 1
START ..\source\scripts\batch\skm_to_omx.bat %1 MD 1
START ..\source\scripts\batch\skm_to_omx.bat %1 PM 1
START ..\source\scripts\batch\skm_to_omx.bat %1 NT 1

START ..\source\scripts\batch\skm_to_omx.bat %1 AM 2
START ..\source\scripts\batch\skm_to_omx.bat %1 MD 2
START ..\source\scripts\batch\skm_to_omx.bat %1 PM 2
START ..\source\scripts\batch\skm_to_omx.bat %1 NT 2

START ..\source\scripts\batch\skm_to_omx.bat %1 AM 3
START ..\source\scripts\batch\skm_to_omx.bat %1 MD 3
START ..\source\scripts\batch\skm_to_omx.bat %1 PM 3
START ..\source\scripts\batch\skm_to_omx.bat %1 NT 3

START ..\source\scripts\batch\skm_to_omx.bat %1 AM 4
START ..\source\scripts\batch\skm_to_omx.bat %1 MD 4
START ..\source\scripts\batch\skm_to_omx.bat %1 PM 4
START ..\source\scripts\batch\skm_to_omx.bat %1 NT 4

:waitForSKMtoOMX
@ping -n 11 127.0.0.1>NUL
if exist %SCEN_DIRECTORY%\outputs\runtime\skm_to_omx\*.error GOTO fastFail
if exist %SCEN_DIRECTORY%\outputs\runtime\skm_to_omx\*.flag GOTO waitForSKMtoOMX

DEL %SCEN_DIRECTORY%\outputs\runtime\skm_to_omx\* /q
RD %SCEN_DIRECTORY%\outputs\runtime\skm_to_omx /q/s

%PYTHON% %PYTHON_SCRIPTS_DIR%\cube_to_omx.py %_iter_% %_prev_% %SCEN_DIRECTORY%
%check_python_errors%

ECHO %startTime%%Time%
ECHO Converting skims to omx complete!

ECHO Making county OMX...
%PYTHON% %PYTHON_SCRIPTS_DIR%\make_county_omx.py -l inputs\landuse\land_use.csv -f JURCODE -i TAZ  -m COUNTY -o %SCEN_DIRECTORY%\outputs\skims\OMX_Skims\county.omx
%check_python_errors%
%PYTHON% %PYTHON_SCRIPTS_DIR%\make_county_omx.py -l inputs\landuse\land_use.csv -f AREATYPE -i TAZ  -m ATYPE -o %SCEN_DIRECTORY%\outputs\skims\OMX_Skims\atype.omx
%check_python_errors%

::SKIMOMX
:: Build skims.omx
ECHO Building skims.omx...
ECHO %startTime%%Time%
%PYTHON% %PYTHON_SCRIPTS_DIR%\build_omx.py %_iter_% %_prev_% %SCEN_DIRECTORY%
%check_python_errors%

ECHO %startTime%%Time%
ECHO Building skims.omx complete!

::EXPLICIT CHUNKING
IF %CHUNK_TRAINING_MODE% EQU explicit (
   ECHO Modifying explicit chunk configurations...
   ECHO %startTime%%Time%
   %PYTHON% %PYTHON_SCRIPTS_DIR%\determine_chunk_sizes.py %SAMPLE% inputs\popsyn %ASIM_CFG_ROOT_DIR%\configs
)

::ASIM
IF NOT EXIST "%SCEN_DIRECTORY%\outputs\activitysim\log" MD "%SCEN_DIRECTORY%\outputs\activitysim\log"
%PYTHON% %PYTHON_SCRIPTS_DIR%\simulation.py -c %ASIM_CFG_ROOT_DIR%\configs_mp -c %ASIM_CFG_ROOT_DIR%\configs -d inputs/popsyn -d inputs/landuse -d outputs/skims/OMX_Skims -o outputs/activitysim
%check_asim_errors%
IF NOT EXIST "outputs\activitysim\final_trips.csv" GOTO ASIMERROR

ECHO ActivitySim run complete!!
ECHO %startTime%%Time%

ECHO %CD%
GOTO ENDABM

:fastFail
ECHO SKM to OMX conversion failed
TIMEOUT 10 /NOBREAK >NUL
TASKKILL /F /IM Voyager.exe >NUL

:CUBEERROR
ECHO There was an error in Cube Voyager - check the preceding step
SET ERROR_FLAG=1
GOTO ENDABM

:ASIMERROR
ECHO There was an error in ActivitySim - check the ActivitySim log files at %SCEN_DIRECTORY%/outputs/activitysim
SET ERROR_FLAG=2
GOTO ENDABM

:PYERROR
ECHO There was an error a Python script - check the model log file at %SCEN_DIRECTORY%/outputs/reports
SET ERROR_FLAG=2
GOTO ENDABM

:ENDABM
ECHO End of ASim Script
@ECHO ON
