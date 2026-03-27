REM  Highway Network Building

if exist voya*.*             del voya*.*
if exist AreaType_File.rpt   del AreaType_File.rpt
start /w Voyager.exe  ..\source\scripts\cube\AreaType_File.s /start -Pvoya -S..\%1
if errorlevel 1 goto error
if exist voya*.prn  copy voya*.prn  outputs\reports\AreaType_File.rpt /y



if exist voya*.*            del voya*.*
if exist V2.3_highway_build.rpt  del V2.3_highway_build.rpt
start /w Voyager.exe      ..\source\scripts\cube\V2.3_highway_build.s /start -Pvoya -S..\%1
if errorlevel 1 goto error
if exist voya*.prn copy voya*.prn    outputs\reports\V2.3_highway_build.rpt /y
if exist temp.net           del temp.net

goto end


:error
REM  Processing Error.....
ECHO Error in PP Highway Build
SET ERROR_FLAG=1
EXIT
:end
