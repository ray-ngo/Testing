ECHO Activate Python Environment....

:: setup paths to Python application, Conda script, etc.
ECHO PYTHON: %PYTHON%

:: Run check script
%PYTHON% ..\source\scripts\python\check_free_space.py

IF %ERRORLEVEL% LSS 0 (
	ECHO INSUFFICIENT DISK SPACE TO CONTINUE!
	exit /b 1
)
exit /b 0
