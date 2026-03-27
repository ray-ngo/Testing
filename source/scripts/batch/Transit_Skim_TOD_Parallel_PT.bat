:: %2 is Mode (CR, MR, AB, BM)
:: %3 is TOD  (AM, MD, PM, NT)

SET TOD_PERIOD=%3
SET workdir=%4

ECHO running>%workdir%\%3.flag
if not exist %workdir%\%3 mkdir %workdir%\%3
del %workdir%\%3\*.* /f/q

start /w Voyager.exe ..\source\scripts\cube\Transit_Skims_PT_%2_PAR.s /start /high -Pvoya -S%workdir%\%3
IF errorlevel 2 GOTO error

GOTO end
:error
echo error>%workdir%\%3.error
EXIT

:end
DEL %workdir%\%3.flag
EXIT
