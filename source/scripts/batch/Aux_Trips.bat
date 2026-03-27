::----------------------------------------
::  Version 3 Auxiliary Trips
::  June 2022 - Andrew Rohne, RSG
::----------------------------------------

ECHO Prepare Truck and Commercial Vehicle Trip Ends
if exist voya*.*  del voya*.*
if exist outputs\reports\%_iter_%_Truck_Com_Trip_Generation.rpt del outputs\reports\%_iter_%_Truck_Com_Trip_Generation.rpt
start /w Voyager.exe  ..\source\scripts\cube\Truck_Com_Trip_Generation.s /start -Pvoya -S.\
if errorlevel 2 goto error
if exist voya*.prn  copy voya*.prn outputs\reports\%_iter_%_Truck_Com_Trip_Generation.rpt /y

ECHO Prepare External Commercial Vehicle and Truck Trip Ends
if exist voya*.*  del voya*.*
if exist outputs\reports\%_iter_%_Prepare_Ext_ComTruck_Ends.rpt del outputs\reports\%_iter_%_Prepare_Ext_ComTruck_Ends.rpt
start /w Voyager.exe  ..\source\scripts\cube\Prepare_Ext_ComTruck_Ends.s /start -Pvoya -S.\
if errorlevel 2 goto error
if exist voya*.prn  copy voya*.prn outputs\reports\%_iter_%_Prepare_Ext_ComTruck_Ends.rpt /y

ECHO Distribute External Truck Trips
if exist voya*.*  del voya*.*
if exist outputs\reports\%_iter_%_Trip_Distribution_ExtTrk.rpt del outputs\reports\%_iter_%_Trip_Distribution_ExtTrk.rpt
start /w Voyager.exe  ..\source\scripts\cube\Trip_Distribution_ExtTrk.s /start -Pvoya -S.\
if errorlevel 2 goto error
if exist voya*.prn  copy voya*.prn outputs\reports\%_iter_%_Trip_Distribution_ExtTrk.rpt /y

ECHO Prepare Internal Commercial Vehicle and Truck Trip Ends
if exist voya*.*  del voya*.*
if exist outputs\reports\%_iter_%_Prepare_Int_ComTruck_Ends.rpt del outputs\reports\%_iter_%_Prepare_Int_ComTruck_Ends.rpt
start /w Voyager.exe  ..\source\scripts\cube\Prepare_Internal_CVTruckEnds.s /start -Pvoya -S.\
if errorlevel 2 goto error
if exist voya*.prn  copy voya*.prn outputs\reports\%_iter_%_Prepare_Int_ComTruck_Ends.rpt /y

ECHO Distribute Intneral Commercial Vehicle and Truck Trip Ends
if exist voya*.*  del voya*.*
if exist outputs\reports\%_iter_%_Trip_Distribution_IntTrk.rpt del outputs\reports\%_iter_%_Trip_Distribution_IntTrk.rpt
start /w Voyager.exe  ..\source\scripts\cube\Trip_Distribution_IntTrk.s /start -Pvoya -S.\
if errorlevel 2 goto error
if exist voya*.prn  copy voya*.prn outputs\reports\%_iter_%_Trip_Distribution_IntTrk.rpt /y

ECHO Prepare Misc Trip (endogenous model) trips by TOD
if exist voya*.*  del voya*.*
if exist outputs\reports\%_iter_%_Misc_Time-of-Day.rpt del outputs\reports\%_iter_%_Misc_Time-of-Day.rpt
start /w Voyager.exe  ..\source\scripts\cube\Misc_Time-of-Day.s /start -Pvoya -S.\
if errorlevel 2 goto error
if exist voya*.prn  copy voya*.prn outputs\reports\%_iter_%_Misc_Time-of-Day.rpt /y

ECHO Prepare Internal-External/External-Internal Auto Passenger Trips
if exist voya*.*  del voya*.*
if exist outputs\reports\%_iter_%_IXXI_TripGeneration.rpt del outputs\reports\%_iter_%_IXXI_TripGeneration.rpt
start /w Voyager.exe  ..\source\scripts\cube\IXXI_TripGeneration.s /start -Pvoya -S.\
if errorlevel 2 goto error
if exist voya*.prn  copy voya*.prn outputs\reports\%_iter_%_IXXI_TripGeneration.rpt /y
ECHO Completed all auxiliary models

goto end

:error
ECHO There was an error in Auxiliary Trips
SET ERROR_FLAG=1
:end
