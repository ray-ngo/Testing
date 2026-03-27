::@ECHO OFF

:: =====================================================================================
:: Note: Individual batch files should return an error code (SET ERROR_FLAG=n)
:: greater than 0 for an error. The current convention is to use 1 for Cube
:: errors and 2 for ActivitySim errors, but nothing actully checks the number
:: except to ensure it is greater than zero.
::
:: Use the batch PAUSE function sparingly if at all. The model should fail
:: verbosely but not stop execution (except at the end) because MWCOG uses
:: AWS servers that should shutdown upon model completion regardless of
:: whether the run was successful.
:: =====================================================================================

:: Maximum number of user equilibrium iterations used in traffic assignment
:: User should not need to change this.  Instead, change _relGap_ (below)
set _maxUeIter_=1000

:: Set transit constraint path and files
:: Current year used to set the constraint = 2020

set _tcpath_=

SET SCEN_NAME=%1
SET SCEN_DIRECTORY=%2
SET BATCH_DIR=%ROOT_DIRECTORY%\source\scripts\batch
SET ERROR_FLAG=0
:: UE relative gap threshold: Progressive (10^-2 for pp-i2, 10^-3 for i3, & 10^-4 for i4)

:: ECHO some settings
ECHO RUN_MINI: %RUN_MINI%
ECHO AUTO_SHUTDOWN: %AUTO_SHUTDOWN%
ECHO TOLL_SETTING: %TOLL_SETTING%

:: ECHO ASIM settings
ECHO ActivitySim CPU: %ASIM_NUM_PROCESSES%
ECHO ActivitySim RAM: %ASIM_RAM_AVAILABLE%

:: Delete the visualizer, if it exists
IF EXIST "%SCEN_DIRECTORY%outputs\%BASELINE_SCENARIO_NAME%_vs_%ALTERNATIVE_SCENARIO_NAME%.html" DEL /Q "%SCEN_DIRECTORY%outputs\%BASELINE_SCENARIO_NAME%_vs_%ALTERNATIVE_SCENARIO_NAME%.html"

if %TOLL_SETTING% EQU False goto TollSettingSkipped

ECHO Perform Toll Setting Processes ...
:: Execute the toll setting processes, which include:
:: 1. Preprocessing that prepares Toll_ESC.dbf with base toll rates
:: 2. Travel demand forecasting in five Speed FeedBack (SFB) loop iterations ('pp', 'i1'-'i4')
:: 3. Heuristic toll searching

ECHO ====== Preprocessing for Toll Setting =================================

call %BATCH_DIR%\Pre_Toll_Setting %1

ECHO ====== Pump Prime Iteration (Toll Setting) ==========================================

set _iter_=pp
set _prev_=pp
set _relGap_=0.01

call %BATCH_DIR%\Set_CPI.bat                %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\PP_Highway_Build.bat       %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\PP_Highway_Skims.bat       %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\Transit_Fare_PT.bat           %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR

ECHO ====== Iteration 1 (Toll Setting) ===================================================

set _iter_=i1
set _prev_=pp
set _relGap_=0.01

call %BATCH_DIR%\Transit_Skim_All_Modes_Parallel_PT.bat %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\RunABM.bat %1 %SCEN_DIRECTORY%
IF %ERROR_FLAG% GTR 0 GOTO ASIMERROR
call %BATCH_DIR%\Aux_Trips.bat %SCEN_DIRECTORY%
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\Highway_Assignment_Prep.bat %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\%HIGHWAY_ASSGN_BAT% %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\Highway_Skims.bat %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR

ECHO ====== Iteration 2 (Toll Setting) ===================================================

set _iter_=i2
set _prev_=i1
set _relGap_=0.01

call %BATCH_DIR%\Transit_Skim_All_Modes_Parallel_PT.bat %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\RunABM.bat %1 %SCEN_DIRECTORY%
IF %ERROR_FLAG% GTR 0 GOTO ASIMERROR
call %BATCH_DIR%\Aux_Trips.bat %SCEN_DIRECTORY%
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\Highway_Assignment_Prep.bat     %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\%HIGHWAY_ASSGN_BAT%     %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\Average_Link_Speeds.bat    %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\Highway_Skims.bat          %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR

ECHO ====== Iteration 3 (Toll Setting) ===================================================

set _iter_=i3
set _prev_=i2
set _relGap_=0.001

call %BATCH_DIR%\Transit_Skim_All_Modes_Parallel_PT.bat %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\RunABM.bat %1 %SCEN_DIRECTORY%
IF %ERROR_FLAG% GTR 0 GOTO ASIMERROR
call %BATCH_DIR%\Aux_Trips.bat %SCEN_DIRECTORY%
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\Highway_Assignment_Prep.bat     %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\%HIGHWAY_ASSGN_BAT%     %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\Average_Link_Speeds.bat    %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\Highway_Skims.bat          %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR

ECHO ====== Iteration 4 (Toll Setting) ===================================================
set _iter_=i4
set _prev_=i3
set _relGap_=0.0001

call %BATCH_DIR%\Transit_Skim_All_Modes_Parallel_PT.bat %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\RunABM.bat %1 %SCEN_DIRECTORY%
IF %ERROR_FLAG% GTR 0 GOTO ASIMERROR
call %BATCH_DIR%\Aux_Trips.bat %SCEN_DIRECTORY%
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\Highway_Assignment_Prep.bat     %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\%HIGHWAY_ASSGN_BAT%     %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\Average_Link_Speeds.bat    %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\Highway_Skims.bat          %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR

ECHO ====== Heuristic Toll Searching ===================================================
call %BATCH_DIR%\Toll_Setting.bat %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR

:: Reset ERROR_FLAG
SET ERROR_FLAG=0

:TollSettingSkipped

ECHO Perform Final Travel Demand Forecasting ...
:: When %TOLL_SETTING% EQU True, toll rates estimated from the above toll setting processes are used;
:: When %TOLL_SETTING% EQU False, pre-existing toll rates are used.

ECHO ====== Pump Prime Iteration (Final Run) ==========================================

set _iter_=pp
set _prev_=pp
set _relGap_=0.01

call %BATCH_DIR%\Set_CPI.bat                %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\PP_Highway_Build.bat       %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\PP_Highway_Skims.bat       %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\Transit_Fare_PT.bat           %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR

ECHO ====== Iteration 1 (Final Run) ===================================================

set _iter_=i1
set _prev_=pp
set _relGap_=0.01

call %BATCH_DIR%\Transit_Skim_All_Modes_Parallel_PT.bat %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\RunABM.bat %1 %SCEN_DIRECTORY%
IF %ERROR_FLAG% GTR 0 GOTO ASIMERROR
call %BATCH_DIR%\Aux_Trips.bat %SCEN_DIRECTORY%
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\Highway_Assignment_Prep.bat %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\%HIGHWAY_ASSGN_BAT% %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\Highway_Skims.bat %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR

if %RUN_MINI% EQU True GOTO I2toI4Skipped

ECHO ====== Iteration 2 (Final Run) ===================================================

set _iter_=i2
set _prev_=i1
set _relGap_=0.01

call %BATCH_DIR%\Transit_Skim_All_Modes_Parallel_PT.bat %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\RunABM.bat %1 %SCEN_DIRECTORY%
IF %ERROR_FLAG% GTR 0 GOTO ASIMERROR
call %BATCH_DIR%\Aux_Trips.bat %SCEN_DIRECTORY%
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\Highway_Assignment_Prep.bat     %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\%HIGHWAY_ASSGN_BAT%     %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\Average_Link_Speeds.bat    %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\Highway_Skims.bat          %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR

ECHO ====== Iteration 3 (Final Run) ===================================================

set _iter_=i3
set _prev_=i2
set _relGap_=0.001

call %BATCH_DIR%\Transit_Skim_All_Modes_Parallel_PT.bat %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\RunABM.bat %1 %SCEN_DIRECTORY%
IF %ERROR_FLAG% GTR 0 GOTO ASIMERROR
call %BATCH_DIR%\Aux_Trips.bat %SCEN_DIRECTORY%
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\Highway_Assignment_Prep.bat     %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\%HIGHWAY_ASSGN_BAT%     %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\Average_Link_Speeds.bat    %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\Highway_Skims.bat          %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR

ECHO ====== Iteration 4 (Final Run) ===================================================
set _iter_=i4
set _prev_=i3
set _relGap_=0.0001

call %BATCH_DIR%\Transit_Skim_All_Modes_Parallel_PT.bat %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\RunABM.bat %1 %SCEN_DIRECTORY%
IF %ERROR_FLAG% GTR 0 GOTO ASIMERROR
call %BATCH_DIR%\Aux_Trips.bat %SCEN_DIRECTORY%
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\Highway_Assignment_Prep.bat     %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\%HIGHWAY_ASSGN_BAT%     %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\Average_Link_Speeds.bat    %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR
call %BATCH_DIR%\Highway_Skims.bat          %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR

:I2toI4Skipped

::
ECHO ====== Transit assignment ============================================
echo Starting Transit Assignment Step
::@date /t & time/t
::
call %BATCH_DIR%\Transit_Assignment_Parallel_PT.bat %1
IF %ERROR_FLAG% GTR 0 GOTO CUBEERROR

:: VISUALIZER
:visualizer
call ..\source\visualizer\generateDashboard.bat
IF %ERROR_FLAG% GTR 0 GOTO VIZERROR

:: View from space
:ViewFromSpace
IF %RUN_MINI% EQU True GOTO MoveTempFiles
call %BATCH_DIR%\view_from_space_gen3.bat %1 %SCEN_DIRECTORY%
IF %ERROR_FLAG% EQU 1 GOTO CUBEERROR
IF %ERROR_FLAG% EQU 2 GOTO PYERROR
call %BATCH_DIR%\Summarize_Person_Trips_from_ActivitySim.bat %1 %SCEN_DIRECTORY%
IF %ERROR_FLAG% EQU 1 GOTO CUBEERROR
IF %ERROR_FLAG% EQU 2 GOTO PYERROR

:: Move unimportant files to a temp folder
:MoveTempFiles
call %BATCH_DIR%\move_temp_files_gen3.bat

:: Delete potentially trailing directories
:DeleteRuntimeWorkdirs
IF EXIST %SCEN_DIRECTORY%\outputs\runtime RMDIR %SCEN_DIRECTORY%\outputs\runtime /q/s

GOTO MSEND

:CUBEERROR
ECHO ===================================================================
ECHO =                              ERROR                              =
ECHO =                                                                 =
ECHO =  There was an error in Cube Voyager - check the preceding step  =
ECHO ===================================================================
SET ERROR_FLAG=1
GOTO MSEND

:ASIMERROR
ECHO ===================================================================
ECHO =                              ERROR                              =
ECHO =                                                                 =
ECHO =    There was an error in ActivitySim - check the output logs    =
ECHO ===================================================================
SET ERROR_FLAG=1
GOTO MSEND

:PYERROR
ECHO ===================================================================
ECHO =                              ERROR                              =
ECHO =                                                                 =
ECHO =      There was an error in Python - check the output logs       =
ECHO ===================================================================
SET ERROR_FLAG=1
GOTO MSEND

:VIZERROR
ECHO ===================================================================
ECHO =                              ERROR                              =
ECHO =                                                                 =
ECHO =  There was an error in the visualizer - check the output logs   =
ECHO ===================================================================
SET ERROR_FLAG=1
GOTO MSEND

:MSEND
if %cubeversion% EQU 25.00.01 (
   TASKKILL /F /IM ClusterManager.exe 1>NUL 2>NUL
)

::@echo End of batch file
::@date /t & time/t
:: rem ====== End of batch file =============================================

REM cd %1
REM copy *.txt MDP_%useMDP%\*.txt
REM copy *.rpt MDP_%useMDP%\*.rpt
REM copy *.log MDP_%useMDP%\*.log
REM CD..

:: set _year_=
:: set _iter_=
:: set _prev_=
:: set _maxUeIter_=
:: set _relGap_=
