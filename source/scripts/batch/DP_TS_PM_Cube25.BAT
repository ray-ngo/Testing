echo running>pm.flag

cd PM

"c:\Program Files\Bentley\OpenPaths\CUBE %cubeversion%\Voyager\VoyagerCLI.exe" ..\..\..\source\scripts\cube\TS_PM_Cube25.S  -P voya -S .\
if %ERRORLEVEL% EQU 2 echo error>../pm.error

cd..
del pm.flag
exit
