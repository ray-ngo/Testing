echo running>am.flag

cd AM

"c:\Program Files\Bentley\OpenPaths\CUBE %cubeversion%\Voyager\VoyagerCLI.exe" ..\..\..\source\scripts\cube\TS_AM_Cube25.S  -P voya -S .\
if %ERRORLEVEL% EQU 2 echo error>../am.error

cd..
del am.flag
exit
