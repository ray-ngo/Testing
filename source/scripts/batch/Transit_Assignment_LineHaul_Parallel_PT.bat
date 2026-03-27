if exist outputs\trn_assign\Transit_Assignment_%2.err   del outputs\trn_assign\Transit_Assignment_%2.err
if exist outputs\trn_assign\Transit_Assignment_%2.done  del outputs\trn_assign\Transit_Assignment_%2.done

@echo Transit_Assignment_%2

SET workdir=.\outputs\runtime\%2

if not exist %workdir% mkdir %workdir%
del %workdir%\*.* /f/q

if exist outputs\reports\%_iter_%_Transit_Assgn_%2.RPT del outputs\reports\%_iter_%_Transit_Assgn_%2.RPT
start /w voyager.exe ..\source\scripts\cube\PT_asgn_%2.s /start -Pvoya -S%workdir%
if errorlevel 2 goto error
if exist %workdir%\voya*.prn copy %workdir%\voya*.prn %workdir%\%_iter_%_Transit_Assgn_%2.RPT /y

del %workdir%\voya*.prn /f/q
copy %workdir%\*.rpt .\outputs\reports\ /y
del %workdir%\*.* /f/q

goto end

:error
echo Error in Transit Assignment %2 > outputs\trn_assign\Transit_Assignment_%2.err
SET ERROR_FLAG=1
EXIT

:end
echo Finished Transit Assignment %2 > outputs\trn_assign\Transit_Assignment_%2.done
rmdir %workdir% /s/q
Exit
