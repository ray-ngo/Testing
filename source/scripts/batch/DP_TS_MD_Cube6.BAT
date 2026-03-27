echo running>md.flag

cd MD

Cluster.exe mdtoll %TSMDsubnode% start exit

start /w Voyager.exe  ../../../source/scripts/cube/TS_MD_Cube6.S /start -Pvoya -S./
if %ERRORLEVEL% EQU 2 echo error>../md.error

Cluster.exe mdtoll %TSMDsubnode% close exit

cd..
del md.flag
exit
