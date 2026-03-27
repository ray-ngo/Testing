:: This program is created to summarize the final resident person trip data from ActivitySim in trip matrices
:: by tour purpose and trip mode. It generates trip tables at the TAZ level in both Open Matrix .omx format
:: and Cube (.trp) format for Gen3 Model run and generates the trip tables at the jur level.

:: Specifically, the program executes the following three scripts in sequence.
:: 1. A Python script (write_omx_trip_tables_from_ActivitySim.py) summarizes the ActivitySim trip data in omx format
:: 2. A Cube Voyager script (convert_trip_tables_omx_to_trp.s) then converts the omx trip matrices into Cube format
:: 3. A Cube Voyager script (Summarize_trip_tables_at_jur_level.s) summarizes trip tables at the jur level


:: the outputs are:
:: - final OMX trip tables (.omx)
:: - final Cube trip tables (.trp)
:: - resident person trip subtotals by tour purpose and trip mode
::   (person_trips_by_tour_purp_and_trip_mode_@scenario_name@.csv)
::   (Trip_tables_at_jur_level_@scenario_name@.csv


:: Created by fxie
:: Last Modified - 9/5/2025

@echo off

CD %ROOT_DIRECTORY%\source\scripts\python

ECHO Summarizing the ActivitySim trip data in OMX trip matrices ...
%PYTHON% write_omx_trip_tables_from_ActivitySim.py %1 %2 > "%SCEN_DIRECTORY%\outputs\reports\i4_omx_trip_tables_from_ActivitySim.rpt"
IF ERRORLEVEL 1 GOTO PYERROR
ECHO .

CD %2

ECHO Converting OMX trip matrices into Cube format (.trp)...
start /w Voyager.exe  ../source/scripts/cube/Convert_trip_tables_omx_to_trp.s /start -Pvoya -S..\%1 %2
IF ERRORLEVEL 2 GOTO CUBEERROR
copy Voya*.prn outputs\reports\Convert_trip_tables_omx_to_trp.rpt /y
ECHO .

ECHO Summarizing person trip tables by tour purpose and by trip model at the jur level...

DEL voya*.* tppl.* /Q
IF EXIST *_trip_tables_at_jur_level*.csv DEL *_trip_tables_at_jur_level*.csv /Q

CD %2

if exist "outputs\hwy_assign\Trip_tables_at_jur_level*.csv" del "outputs\hwy_assign\Trip_tables_at_jur_level*.csv"
start /w Voyager.exe  ../source/scripts/cube/Summarize_trip_tables_at_jur_level.s /start -Pvoya -S..\%1 %2
IF ERRORLEVEL 2 GOTO CUBEERROR
copy Voya*.prn outputs\reports\Summarize_trip_tables_at_jur_level.rpt /y

if exist voya*.prn del voya*.prn
if exist TPPL*.* del TPPL*.*
if exist voya*.var del voya*.var
if exist DJ*.* del DJ*.*

goto end

:CUBEERROR
ECHO There was an error in Cube Voyager - check the preceding step
SET ERROR_FLAG=1
GOTO end

:PYERROR
ECHO There was an error in write_omx_trip_tables_from_ActivitySim.py - check the model log file at %SCEN_DIRECTORY%/outputs/reports
SET ERROR_FLAG=2
GOTO end

:end
@ECHO ON
