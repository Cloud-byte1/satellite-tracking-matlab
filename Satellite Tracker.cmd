@echo off
setlocal
set "SATELLITE_TRACKER_STANDALONE=1"
set "MATLAB_EXE=C:\Program Files\MATLAB\R2026b\bin\matlab.exe"

if not exist "%MATLAB_EXE%" (
    echo MATLAB R2026b was not found at:
    echo %MATLAB_EXE%
    echo.
    echo Install MATLAB R2026b or update MATLAB_EXE in this launcher.
    pause
    exit /b 1
)

start "Satellite Tracker" "%MATLAB_EXE%" -nosplash -nodesktop -sd "%~dp0" -r "launchSatelliteTracker;"
endlocal
