:: Combine Mode Choice Output for Transit Assignment

if exist voya*.* del voya*.*
if exist outputs\reports\%_iter_%_Combine_Tables_For_TrAssign_Parallel.RPT del outputs\reports\%_iter_%_Combine_Tables_For_TrAssign_Parallel.RPT

:::: convert external and visitor trips from OMX to TRP (needs to be called only if OMXs have changed)
start /w voyager.exe ..\source\scripts\cube\Convert_Ext_Vis_Transit_Tables_to_TRP.s /start -Pvoya -S..\%1

:: combine internal, external and visitor trips for assignment
start /w voyager.exe ..\source\scripts\cube\Combine_Int_Ext_Tables_For_TrAssign_Parallel.s /start -Pvoya -S..\%1


if errorlevel 2 goto error
if exist voya*.prn copy voya*.prn outputs\reports\%_iter_%_Combine_Tables_For_TrAssign_Parallel.RPT /y

:: =======================================
:: = Transit Assignment Section          =
:: =======================================

:Parallel_Processing
@echo Start Transit Assignments - Parallel

IF NOT EXIST .\outputs\runtime MKDIR .\outputs\runtime

start "" /wait cmd /c ..\source\scripts\batch\Transit_Assignment_LineHaul_Parallel_PT.bat %1 CR |start "" /wait cmd /c ..\source\scripts\batch\Transit_Assignment_LineHaul_Parallel_PT.bat %1 MR |start "" /wait cmd /c ..\source\scripts\batch\Transit_Assignment_LineHaul_Parallel_PT.bat %1 AB |start "" /wait cmd /c ..\source\scripts\batch\Transit_Assignment_LineHaul_Parallel_PT.bat %1 BM

:Transit_Assignments_Are_Done

@REM Check file existence to ensure that there are no errors
if exist outputs\trn_assign\Transit_Assignment_CR.err echo Error in Transit_Assignment_CR && goto error
if exist outputs\trn_assign\Transit_Assignment_MR.err echo Error in Transit_Assignment_MR && goto error
if exist outputs\trn_assign\Transit_Assignment_AB.err echo Error in Transit_Assignment_AB && goto error
if exist outputs\trn_assign\Transit_Assignment_BM.err echo Error in Transit_Assignment_BM && goto error

RMDIR .\outputs\runtime /s/q
GOTO end

:error
ECHO Error in Transit Assignment
SET ERROR_FLAG=1
EXIT /b 1

:end
if exist voya*.prn  copy voya*.prn outputs\reports\Transit_assignment.rpt /y
if exist voya*.*  del voya*.*
