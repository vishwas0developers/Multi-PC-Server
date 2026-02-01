@echo off
setlocal enabledelayedexpansion
title GLM-4.6 Host PC Windows Controller
color 0E

echo ======================================
echo  GLM-4.6 Host PC Windows Controller
echo ======================================
echo.

set SCRIPT_DIR=%~dp0
set SH_FILE=%SCRIPT_DIR%setup_host_pc.sh

if not exist "%SH_FILE%" (
    echo ERROR: setup_host_pc.sh not found in same folder!
    pause
    exit /b 1
)

echo [OK] Found setup_host_pc.sh
echo.

wsl -e bash -c "sudo mkdir -p /cluster/host_setup ; sudo chown $USER:$USER /cluster/host_setup" || (
    echo ERROR: Cannot create /cluster/host_setup
    pause
    exit /b 1
)

echo Copying script into WSL...
type "%SH_FILE%" | wsl -e bash -c "cat > /cluster/host_setup/setup_host_pc.sh" || (
    echo ERROR: Copy failed
    pause
    exit /b 1
)

wsl -e bash -c "sed -i 's/\r$//' /cluster/host_setup/setup_host_pc.sh"
wsl -e bash -c "chmod +x /cluster/host_setup/setup_host_pc.sh"

echo [OK] Script copied and prepared.
echo.

echo ======================================
echo Running Host Setup in WSL...
echo ======================================
echo.

wsl -e bash -c "/cluster/host_setup/setup_host_pc.sh"
set WSL_ERROR=%errorlevel%

echo.
echo WSL Exit Code = %WSL_ERROR%
echo.

if not "%WSL_ERROR%"=="0" (
    echo ERROR: Host setup failed inside WSL.
    pause
    exit /b 1
)

echo ======================================
echo SUCCESS: Host PC Setup Completed
echo ======================================
pause
exit /b 0
