if exist "outputs\auxiliary\*.csv" del "outputs\auxiliary\*.csv"
start /w Voyager.exe  ../source/scripts/cube/view_from_space_gen3_external_exogenous_trips.s /start -Pvoya -S..\%1
IF ERRORLEVEL 2 GOTO CUBEERROR

copy Voya*.prn outputs\reports\view_from_space_gen3_external_exogenous_trips.rpt /y

CD %ROOT_DIRECTORY%\source\scripts\python
%PYTHON%  view_from_space_gen3.py %SCEN_DIRECTORY% %SCEN_NAME%
IF ERRORLEVEL 1 GOTO PYERROR
CD %SCEN_DIRECTORY%

if exist voya*.prn del voya*.prn
if exist TPPL*.* del TPPL*.*
if exist voya*.var del voya*.var

goto end

:CUBEERROR
ECHO There was an error in view_from_space_gen3_external_exogenous_trips.s - check .prn file
SET ERROR_FLAG=1
GOTO end

:PYERROR
ECHO There was an error in view_from_space_gen3.py - check the model log file at %SCEN_DIRECTORY%/outputs/reports
SET ERROR_FLAG=2
GOTO end

:end
