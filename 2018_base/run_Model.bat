::####################################################################################################################
::
:: MWCOG Gen 3 Model
::
::####################################################################################################################
::@ECHO OFF

:: ================= USER SPECIFICATIONS========================================
:: STEP ONE: Choose the version of Cube.
:: Possible values are: 6.5.1 or 25.00.01
:: 6.5.1 is for Cube CE 6.5.1 and 25.00.01 is for OpenPaths Cube 2025 version 25.00.01
set cubeversion=6.5.1

:: STEP TWO: Set model year
set _year_=2018

:: STEP THREE: Set Python environment name
:: Make sure this environment is installed following the instructions in README.md
SET PYENVNAME=gen3_model151

:: STEP FOUR: Set PYTHON path
SET PYTHON=C:\Users\%USERNAME%\%PYENVNAME%\.venv\Scripts\python.exe

:: STEP FIVE: Set RUN_MINI to True to skip Iterations 2 to 4 of the model
:: This "mini" version reduces the model's footprint in terms of runtime and storage space
:: and is suffcient for tasks like functionality testing and benchmarking.
:: It is recommendeded to include "_mini" in the scenario folder name to indicate a mini run.
SET RUN_MINI=False

:: STEP SIX: Set AUTO_SHUTDOWN to True to automatically shut down a server at the end of a model run
:: This is useful when the model is run on an on-demand cloud server that is charged by hours used.
SET AUTO_SHUTDOWN=False

:: STEP SEVEN: Set TOLL_SETTING to True to turn on the toll setting processing
:: When TOLL_SETTING is turned off, the model runs use the toll inputs in the "Toll_Esc.dbf" file.
SET TOLL_SETTING=False

:: ----------------- VISUALIZER SETTINGS --------------------------------

:: STEP EIGHT: Set IS_BASE_SURVEY to Yes or No to compare the activitysim output to the survey or a previous run
:: Set to Yes: Compare against 2017/2018 survey data and skip STEP NINE.
:: Set to No: Compare against a previous run. Proceed to STEP NINE to specify the path and run names.
SET IS_BASE_SURVEY=Yes

:: STEP NINE: Comparison setting
:: Note: Skip this step if IS_BASE_SURVEY is set to "Yes"

:: 1. Set BASELINE_SCENARIO_PATH to full folder path of an available model run (the reference baseline).
:: Example: D:\ModelRuns\MWCOG_Gen3_Model\2018_base
SET BASELINE_SCENARIO_PATH=

:: 2. Set BASELINE_SCENARIO_NAME to the name for the baseline scenario defined above.
:: Example: 2018Base
SET BASELINE_SCENARIO_NAME=

:: 3. Set ALTERNATIVE_SCENARIO_NAME to the name of this current (Alternative) run.
:: Example: 2018Build
SET ALTERNATIVE_SCENARIO_NAME=


:: ================= DEFAULT MODEL SPECIFICATIONS =======================

:: setup folders
SET SCEN_DRIVE=%~d0
ECHO SCEN_DRIVE: %SCEN_DRIVE%

SET SCEN_DIRECTORY=%~dp0
ECHO SCEN_DIRECTORY: %SCEN_DIRECTORY%

CD ..
SET ROOT_DIRECTORY=%CD%
ECHO ROOT_DIRECTORY: %ROOT_DIRECTORY%

CD %SCEN_DIRECTORY%

SET BATCH_DIR=%ROOT_DIRECTORY%\source\scripts\batch
ECHO BATCH_DIR: %BATCH_DIR%

SET ASIM_CFG_ORIG_DIR=%ROOT_DIRECTORY%\source\configs\activitysim
ECHO ASIM_CFG_ORIG_DIR: %ASIM_CFG_ORIG_DIR%

SET ASIM_CFG_ROOT_DIR=%SCEN_DIRECTORY%\asim_configs
ECHO ASIM_CFG_ROOT_DIR: %ASIM_CFG_ROOT_DIR%

:: setup dependencies, which are one folder up so they can be shared across scenarios
SET TIMETHIS_PATH=%ROOT_DIRECTORY%\source\software\application\TIMETHIS.exe
ECHO TIMETHIS_PATH: %TIMETHIS_PATH%

SET TEE_PATH=%ROOT_DIRECTORY%\source\software\application\Tee.exe
ECHO TEE_PATH: %TEE_PATH%

:: Always turn off toll setting for chuck training and a MINI run.
if %RUN_MINI% EQU True set TOLL_SETTING=False

:: Set fleet year variable in ActivitySim (don't change this!)
SET /a _fleetyear_=%_year_%-1


:: ================= MODEL EXECUTION ======================================

:: Set scenario name
for %%S in (.) do set "scenar=%%~nxS"
echo %scenar%

:: Checks and setups before executing the model run
@ECHO OFF

:: Check if root and scenario path is free of hyphens
ECHO "%CD%" | find "-" >NUL
IF %ERRORLEVEL% EQU 0 (
   CALL :ErrorPrelude
   ECHO The root and/or scenario paths contain one or more hyphens, which is incompatible with Cube.
   ECHO Please remove or exchange the hyphens and restart the model run.
   CALL :ErrorClosing
   GOTO FinalPause
)

:: Check if the specified Python path actually exists
if not exist "%PYTHON%" (
   CALL :ErrorPrelude
   ECHO The specified Python path does not exist. Please verify that the gen3_model environment is correctly installed under C:\Users\%USERNAME%.
   CALL :ErrorClosing
   GOTO FinalPause
)

:: Check if cubeversion is valid
IF %cubeversion% NEQ 6.5.1 (
   IF %cubeversion% NEQ 25.00.01 (
      CALL :ErrorPrelude
      ECHO Invalid Cube version set! Possible cubeversion values are 6.5.1 or 25.00.01.
      CALL :ErrorClosing
      GOTO FinalPause
   )
)

:: Check if there is sufficient free hard disk space for the model run
call %BATCH_DIR%\check_free_space.bat

:: Set BASELINE_SUMMARY_DIR and check if it exists
SET BASELINE_SUMMARY_DIR=%ROOT_DIRECTORY%\source\visualizer\dependencies\data\summarized_survey
IF NOT %IS_BASE_SURVEY% EQU Yes (
   SET BASELINE_SUMMARY_DIR=%BASELINE_SCENARIO_PATH%\outputs\visualizer
)

IF NOT EXIST %BASELINE_SUMMARY_DIR% (
   CALL :ErrorPrelude
   ECHO BASELINE_SUMMARY_DIR: %BASELINE_SUMMARY_DIR%
   ECHO Baseline summary to compare to does not exist. Please verify parameters.
   CALL :ErrorClosing
   GOTO FinalPause
)

:: Set the visualizer name for the baseline and alternative scenarios if comparing to survey
IF %IS_BASE_SURVEY% EQU Yes (
   SET BASELINE_SCENARIO_NAME=SURVEY
   SET ALTERNATIVE_SCENARIO_NAME=%scenar%
) ELSE (
  IF [%BASELINE_SCENARIO_NAME%] EQU [] (
     CALL :ErrorPrelude
     ECHO Comparing against an existing run, please specify BASELINE_SCENARIO_NAME.
     CALL :ErrorClosing
     GOTO FinalPause
  )
  IF [%ALTERNATIVE_SCENARIO_NAME%] EQU [] (
     CALL :ErrorPrelude
     ECHO Comparing against an existing run, please specify ALTERNATIVE_SCENARIO_NAME.
     CALL :ErrorClosing
     GOTO FinalPause
  )
)

:: Create outputs folder and its sub-folders
call %BATCH_DIR%\create_outputs_folders.bat

:: Set ABM_SUMMARY_DIR
SET ABM_SUMMARY_DIR=%SCEN_DIRECTORY%outputs\visualizer

set runbat=%SCEN_DIRECTORY%\run_ModelSteps.bat
:: Environment variables for (multistep) distributed processing:
:: Environment variables for (intrastep) distributed processing:
::     use MDP = t/f (for true or false)
::     use IDP = t/f (for true or false)
::     Number of subnodes:  1-3 => 3 subnodes and one main node = 4 nodes in total
set useIdp=t
set useMdp=t

:: CUBE 6.5.1 settings
IF %cubeversion% EQU 6.5.1 (
   REM 05/10/2019 AMsubnode, MDsubnode, PMsubnode, NTsubnode are used in highway_assignment_parallel_cube6.bat/s
   set AMsubnode=1-7
   set MDsubnode=1-2
   set PMsubnode=1-6
   set NTsubnode=1-1

   REM subprocesses used in toll setting (DP_TS_*_Cube6.bat, TS_*_Cube6.s)
   REM AM and PM settings
   set TSsubnode=1-8

   REM MD settings
   set TSMDsubnode=1-16

   REM Highway assignment batch file
   set HIGHWAY_ASSGN_BAT=Highway_Assignment_Parallel_Cube6.bat

   REM Toll setting batch files
   set TOLL_SETTING_MD_BAT=DP_TS_MD_Cube6.BAT
   set TOLL_SETTING_AM_BAT=DP_TS_AM_Cube6.BAT
   set TOLL_SETTING_PM_BAT=DP_TS_PM_Cube6.BAT
)

:: CUBE 25.00.01 settings
IF %cubeversion% EQU 25.00.01 (
   REM Total number of cluster processes
   set TotalClusterProcesses=16

   REM 07/25/2025 AMClusterProcesses, MDClusterProcesses, PMClusterProcesses, NTClusterProcesses are used in highway_assignment_parallel_cube25.bat/s
   set AMClusterProcesses=7
   set MDClusterProcesses=2
   set PMClusterProcesses=6
   set NTClusterProcesses=1

   REM subprocesses used in toll setting (DP_TS_*_Cube25.bat, TS_*_Cube25.s)
   REM AM and PM settings
   set TSClusterProcesses=8

   REM MD settings
   set TSMDClusterProcesses=16

   REM Highway assignment batch file
   set HIGHWAY_ASSGN_BAT=Highway_Assignment_Parallel_Cube25.bat

   REM Toll setting batch files
   set TOLL_SETTING_MD_BAT=DP_TS_MD_Cube25.BAT
   set TOLL_SETTING_AM_BAT=DP_TS_AM_Cube25.BAT
   set TOLL_SETTING_PM_BAT=DP_TS_PM_Cube25.BAT
)

:: Try to close all ClusterManager.exe instances and cancel the model run if there is still an
:: instance left over
SET CM_INSTANCES_COUNT=0
if %cubeversion% EQU 25.00.01 (
   TASKKILL /F /IM ClusterManager.exe 1>NUL 2>NUL
   for /f "tokens=1,*" %%a in ('tasklist /FI "imagename eq ClusterManager.exe" ^| find /I /C "ClusterManager.exe"') do set CM_INSTANCES_COUNT=%%a
)
IF %CM_INSTANCES_COUNT% GTR 0 (
   CALL :ErrorPrelude
   ECHO There is a remaining ClusterManager instance running - please close it before trying to run the model again.
   CALL :ErrorClosing
   GOTO FinalPause
)

:: Check if computer specs are adequate, if asim settings are set properly.
:: May also update cluster settings if a higher multiple 16 cores is available (32, 48, etc).
:: Will also make updates to asim settings to match computer specs more appropriately.
SET ENV_TMP_FILE=env_temp_file.txt
%PYTHON% ..\source\scripts\python\check_comp_specs_and_set.py
if errorlevel 1 GOTO FinalPause
for /F "tokens=1,2 delims==" %%A in (%ENV_TMP_FILE%) do SET %%A=%%B
DEL %ENV_TMP_FILE%
@ECHO On

:: Setup activitysim config directory
XCOPY /S /Y %ASIM_CFG_ORIG_DIR% %ASIM_CFG_ROOT_DIR%\ >NUL

:: This command will
::  1) time the model run (using timethis.exe and the double quotes)
::  2) redirect standard output and standard error to a file
::  3) Use the tee command so that stderr & stdout are sent both to the file and the screen

%TIMETHIS_PATH% "call %runbat%  %scenar% %SCEN_DIRECTORY% " 2>&1 | %TEE_PATH% %SCEN_DIRECTORY%\outputs\reports\%scenar%_fulloutput.txt
::call %runbat%  %scenar% %ROOT_DIRECTORY%

:::: Open up the file containing the stderr and stdout
::if exist %root%\%scenar%\%scenar%_fulloutput.txt     start %root%\%scenar%\%scenar%_fulloutput.txt
::
:::: Look four errors in the reports and output files
::call searchForErrs.bat  %scenar%
:::: Open up the file containing any errors found
::if exist %root%\%scenar%\%scenar%_searchForErrs.txt  start %root%\%scenar%\%scenar%_searchForErrs.txt
::
:::: Open up other report files
::if exist %root%\%scenar%\i4_Highway_Assignment.rpt   start %root%\%scenar%\i4_Highway_Assignment.rpt
::if exist %root%\%scenar%\i4_mc_NL_summary.txt        start %root%\%scenar%\i4_mc_NL_summary.txt
::if exist %root%\%scenar%\i4_Assign_Output.net        start %root%\%scenar%\i4_Assign_Output.net
::cd %scenar%
::start powershell.exe -noexit -Command get-content i4_ue*AM_nonHov*txt -tail 1; get-content i4_ue*AM_hov*txt -tail 1; get-content i4_ue*PM_nonHov*txt -tail 1; get-content i4_ue*PM_hov*txt -tail 1; get-content i4_ue*MD*txt -tail 1; get-content i4_ue*NT*txt -tail 1
::cd ..

GOTO end

:: ================= FUNCTIONS ========================================
:ErrorPrelude
ECHO ===================================================================
ECHO =                              ERROR                              =
EXIT /b

:ErrorClosing
ECHO Exiting model run.
ECHO ===================================================================
EXIT /b

:end
:: Cleanup
set root=
set scenar=
set runbat=
set useIdp=
set useMdp=
set AMsubnode=
set MDsubnode=
set PMsubnode=
set NTsubnode=
set subnode=

IF %AUTO_SHUTDOWN% EQU True call %BATCH_DIR%\shutdown_60s.bat

:FinalPause
PAUSE
