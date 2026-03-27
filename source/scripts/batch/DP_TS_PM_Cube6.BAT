echo running>pm.flag

cd PM

Cluster.exe pmtoll %TSsubnode% start exit

start /w Voyager.exe  ../../../source/scripts/cube/TS_PM_Cube6.S /start -Pvoya -S./
if %ERRORLEVEL% EQU 2 echo error>../pm.error

Cluster.exe pmtoll %TSsubnode% close exit

cd..
del pm.flag
exit
