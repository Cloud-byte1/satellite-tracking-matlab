@echo off
setlocal
set "MATLAB_EXE=C:\Program Files\MATLAB\R2026b\bin\matlab.exe"

if not exist "%MATLAB_EXE%" (
    echo MATLAB R2026b was not found at:
    echo %MATLAB_EXE%
    echo.
    echo Install MATLAB R2026b or update MATLAB_EXE in this launcher.
    pause
    exit /b 1
)

if /I "%~1"=="--test" (
    "%MATLAB_EXE%" -batch "cd('%~dp0'); assert(exist('launchSatelliteTracker','file')==2); fprintf('SATELLITE_TRACKER_LAUNCHER_TEST=PASS\n');"
    exit /b %ERRORLEVEL%
)

"%MATLAB_EXE%" -r "cd('%~dp0'); setenv('SATELLITE_TRACKER_STANDALONE','1'); launchSatelliteTracker;"
endlocal
