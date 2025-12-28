@echo off
echo ================================================
echo   Windows Setup Installation Package
echo ================================================
echo.
echo Extracting files...

REM Get the directory where this batch file is located
set SCRIPT_DIR=%~dp0

REM Extract the zip file
powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%SCRIPT_DIR%setup-package.zip' -DestinationPath '%SCRIPT_DIR%extracted' -Force"

echo.
echo Running setup script...
echo.

REM Run the setup script as administrator
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%SCRIPT_DIR%extracted\setup.ps1""' -Verb RunAs"

echo.
echo Installation started. Check the elevated PowerShell window.
echo.
pause
