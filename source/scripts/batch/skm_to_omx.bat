CD %SCEN_DIRECTORY%\outputs\runtime\skm_to_omx

ECHO running>%2%3.flag
if not exist %2%3 mkdir %2%3
del %2%3\*.* /f/q

SET TOD_PERIOD=%2
SET SKM_GROUP=%3

START /w Voyager %ROOT_DIRECTORY%\source\scripts\cube\SKM_to_OMX.s /start /high -Pvoya -S.\%2%3
IF errorlevel 2 GOTO error

GOTO end
:error
echo error>%2%3.error
EXIT

:end
DEL %2%3.flag
EXIT
