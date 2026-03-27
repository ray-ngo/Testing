if exist voya*.*  del voya*.*
if exist outputs\reports\%_iter_%_aux_auto_pax_ixxi.rpt  del outputs\reports\%_iter_%_aux_auto_pax_ixxi.rpt
start /w Voyager.exe  ..\source\scripts\cube\IXXI_TripGeneration.s /start -Pvoya -S..\%1