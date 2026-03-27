echo running>am.flag

cd AM

Cluster.exe amtoll %TSsubnode% start exit

start /w Voyager.exe  ../../../source/scripts/cube/TS_AM_Cube6.S /start -Pvoya -S./
if %ERRORLEVEL% EQU 2 echo error>../am.error

Cluster.exe amtoll %TSsubnode% close exit

cd..
del am.flag
exit
