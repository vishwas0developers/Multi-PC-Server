@echo off
title Fixing Startup Task (No Popup + No Error)
color 0A

echo ==========================================
echo    Removing OLD incorrect startup task
echo ==========================================
schtasks /delete /tn "admin_Apps_Startup" /f >nul 2>&1

echo.
echo ==========================================
echo    Creating NEW Corrected Startup Task
echo ==========================================

set TASK_NAME=SilentStartupApps
set VBS_FILE=C:\Users\manra\admin_startup.vbs

if not exist "%VBS_FILE%" (
    echo ERROR: %VBS_FILE% not found!
    pause
    exit /b
)

schtasks /create ^
 /tn "%TASK_NAME%" ^
 /tr "wscript.exe \"%VBS_FILE%\"" ^
 /sc onlogon ^
 /rl highest ^
 /f

if %errorlevel%==0 (
    echo.
    echo Task created successfully!
    echo No more popups.
    echo VBS will run invisibly and silently now.
) else (
    echo.
    echo Failed to create task.
)

echo.
pause
