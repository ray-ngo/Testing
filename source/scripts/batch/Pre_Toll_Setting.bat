SET MAXTGRPS=1000

if exist .\inputs\hwy\toll_esc_old.dbf del .\inputs\hwy\toll_esc_old.dbf
ren .\inputs\hwy\toll_esc.dbf toll_esc_old.dbf

if errorlevel 1 goto error

start /w Voyager.exe  ../source/scripts/cube/Prepare_Base_Toll_Esc_File.s /start -Pvoya -S./inputs/hwy

if exist .\inputs\hwy\voya*.* del .\inputs\hwy\voya*.*
if exist .\inputs\hwy\tppl*.* del .\inputs\hwy\tppl*.*

goto end
:error
ECHO Error in Prepare Toll Setting
SET ERROR_FLAG=1

:end
