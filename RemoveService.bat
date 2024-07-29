@echo off
setlocal

rem Prompt the user for the service name
set /p ServiceName=Enter the name of the Windows service to stop and remove: 

rem Check if the service exists
sc query "%ServiceName%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Service "%ServiceName%" does not exist.
    goto :end
)

rem Attempt to stop the service
echo Stopping the service "%ServiceName%"...
sc stop "%ServiceName%"
if %errorlevel% neq 0 (
    echo Service "%ServiceName%" is not running or failed to stop, proceeding to delete.
) else (
    rem Wait for the service to stop
    :waitloop
    timeout /t 1 >nul
    sc query "%ServiceName%" | findstr /i /c:"STOPPED" >nul
    if %errorlevel% neq 0 (
        goto waitloop
    )
    echo Service "%ServiceName%" stopped successfully.
)

rem Remove the service
echo Removing the service "%ServiceName%"...
sc delete "%ServiceName%"
if %errorlevel% neq 0 (
    echo Failed to delete the service "%ServiceName%".
    goto :end
)

echo Service "%ServiceName%" has been successfully removed.

:end
endlocal
pause
