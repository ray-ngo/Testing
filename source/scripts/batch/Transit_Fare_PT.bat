::--------------------------------------
::  Version 2.5 Transit Fare Process
::--------------------------------------
:: rqn Add script V2.5_PTNet_Build.s to build PT Network as part of the model
ECHO Running Transit Fare Process...

::copy transit line files from the inputs subdir.
:: copy inputs\trn\Mode*.lin /y

:: adjust local bus run times by applying bus speed degradation factors.
:: (Added 1/13/21 by fxie)
:: rngo, 5/15/22: Changed the errorlevel from 1 to 2 due to the CPI reading error code of 1
if exist voya*.*  del voya*.*
if exist outputs\reports\Adjust_Runtime.rpt  del outputs\reports\Adjust_Runtime.rpt
start /w Voyager.exe  ..\source\scripts\cube\Adjust_Runtime_PT.s /start -Pvoya -S..\%1
if errorlevel 2 goto error
if exist voya*.prn  copy voya*.prn outputs\reports\Adjust_Runtime.rpt /y

::copy transit support files from the inputs subdir.
:: copy inputs\trn\*.TB /y
:: copy inputs\trn\mfare1.a1 /y

::develop PT network building process
if exist voya*.*  del voya*.*
if exist outputs\reports\V2.5_PTNet_Build.rpt  del outputs\reports\V2.5_PTNet_Build.rpt
start /w Voyager.exe  ..\source\scripts\cube\V2.5_PTNet_Build.S /start -Pvoya -S..\%1
if errorlevel 2 goto error
if exist voya*.prn  copy voya*.prn outputs\reports\V2.5_PTNet_Build.rpt /y


if exist voya*.*  del voya*.*
if exist outputs\reports\%_iter_%_prefarV23.rpt  del outputs\reports\%_iter_%_prefarV23.rpt
start /w Voyager.exe  ..\source\scripts\cube\prefarV23.s /start -Pvoya -S..\%1
if errorlevel 2 goto error
if exist voya*.prn  copy voya*.prn outputs\reports\%_iter_%_prefarV23.rpt /y



if exist voya*.*  del voya*.*
if exist outputs\reports\%_iter_%_Metrorail_skims.rpt  del outputs\reports\%_iter_%_Metrorail_skims.rpt
start /w Voyager.exe  ..\source\scripts\cube\Metrorail_skims.s /start -Pvoya -S..\%1
if errorlevel 2 goto error
if exist voya*.prn  copy voya*.prn outputs\reports\%_iter_%_Metrorail_skims.rpt /y


if exist voya*.*  del voya*.*
if exist outputs\reports\%_iter_%_MFARE1.rpt  del outputs\reports\%_iter_%_MFARE1.rpt
start /w Voyager.exe  ..\source\scripts\cube\MFARE1.s /start -Pvoya -S..\%1
if errorlevel 2 goto error
if exist voya*.prn  copy voya*.prn outputs\reports\%_iter_%_MFARE1.rpt /y


goto end


:error
ECHO Error in Transit_Fare_PT.bat
SET ERROR_FLAG=1
EXIT
:end
