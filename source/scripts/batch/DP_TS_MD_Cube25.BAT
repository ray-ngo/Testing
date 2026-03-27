echo running>md.flag

cd MD

TASKKILL /IM ClusterManager.exe /F
"c:\Program Files\Bentley\OpenPaths\CUBE %cubeversion%\Voyager\VoyagerCLI.exe" ..\..\..\source\scripts\cube\TS_MD_Cube25.S  -P voya -S .\
if %ERRORLEVEL% EQU 2 echo error>../md.error

cd..
del md.flag
exit
