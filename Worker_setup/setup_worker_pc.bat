@echo off
setlocal enabledelayedexpansion
title GLM-4.6 Worker PC Windows Controller
color 0B

echo ======================================
echo  GLM-4.6 Worker PC Windows Controller
echo ======================================
echo.

set SCRIPT_DIR=%~dp0
set SH_FILE=%SCRIPT_DIR%setup_worker_pc.sh

if not exist "%SH_FILE%" (
    echo ERROR: setup_worker_pc.sh not found in same folder!
    pause
    exit /b 1
)

echo [OK] Found setup_worker_pc.sh
echo.

echo Checking WSL and Ubuntu...
wsl -l >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: WSL or a Linux distribution is not installed or not available.
    echo Please make sure:
    echo   1. WSL is enabled.
    echo   2. Ubuntu is installed.
    echo   3. Ubuntu has been opened at least once and a user created.
    echo Then run this script again.
    pause
    exit /b 1
)

echo [OK] WSL and a Linux distribution are available.
echo.

echo Preparing worker setup folder in WSL...
wsl -e bash -c "sudo mkdir -p /cluster/worker_setup ; sudo chown $USER:$USER /cluster/worker_setup" || (
    echo ERROR: Cannot create /cluster/worker_setup in WSL.
    pause
    exit /b 1
)

echo Copying script into WSL...
type "%SH_FILE%" | wsl -e bash -c "cat > /cluster/worker_setup/setup_worker_pc.sh" || (
    echo ERROR: Copy failed.
    pause
    exit /b 1
)

wsl -e bash -c "sed -i 's/\r$//' /cluster/worker_setup/setup_worker_pc.sh"
wsl -e bash -c "chmod +x /cluster/worker_setup/setup_worker_pc.sh"

echo [OK] Script copied and prepared.
echo.

echo ======================================
echo Running Worker Setup in WSL...
echo ======================================
echo.

wsl -e bash -c "/cluster/worker_setup/setup_worker_pc.sh"
set WSL_ERROR=%errorlevel%

echo.
echo WSL Exit Code = %WSL_ERROR%
echo.

if not "%WSL_ERROR%"=="0" (
    echo ERROR: Worker setup failed inside WSL.
    echo Please scroll up and read the WSL-side error messages.
    pause
    exit /b 1
)

echo ======================================
echo SUCCESS: Worker PC Setup Completed
echo ======================================
pause
exit /b 0
