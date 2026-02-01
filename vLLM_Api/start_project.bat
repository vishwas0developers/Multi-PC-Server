@echo off
setlocal enabledelayedexpansion
title Start vLLM API Server (Existing Ray Cluster)
color 0E

:: =========================================================
::  USER CONFIGURATION
:: =========================================================
set WSL_PASSWORD=6162

:: =========================================================
::  AUTO-ADMIN REQUEST
:: =========================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~dpnx0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
echo ============================================
echo    Starting vLLM API Server
echo    (Connecting to EXISTING Ray Cluster)
echo ============================================
echo.
:: =========================================================
::  1. DETECT NETWORK
:: =========================================================
echo [1/4] Detecting Network...
for /f "usebackq tokens=*" %%A in (`powershell -Command "(Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -ne $null -and $_.NetAdapter.Status -eq 'Up' } | Select-Object -First 1).IPv4Address.IPAddress"`) do set WIN_IP=%%A

:: Robust WSL IP Detection
for /f "usebackq tokens=1" %%B in (`wsl bash -c "hostname -I | awk '{print $1}'"`) do set WSL_IP=%%B
set WSL_IP=%WSL_IP: =%

if "%WIN_IP%"=="" (
    echo ERROR: Could not detect Windows IP.
    pause
    exit /b
)
echo      Windows IP: %WIN_IP%
echo      WSL IP:     %WSL_IP%

:: =========================================================
::  2. CONFIGURE NETWORK (Ensure API Port is Open)
:: =========================================================
echo [2/4] Configuring Port Forwarding (Ports 8000, 8001)...
:: Clear old rules to avoid conflicts
netsh interface portproxy delete v4tov4 listenport=8000 listenaddress=0.0.0.0 >nul 2>&1
netsh interface portproxy delete v4tov4 listenport=8001 listenaddress=0.0.0.0 >nul 2>&1

:: Add new rules
netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=8000 connectaddress=%WSL_IP% connectport=8000
netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=8001 connectaddress=%WSL_IP% connectport=8001

echo [3/4] Configuring Firewall...
netsh advfirewall firewall show rule name="Ray_LLM_8000" >nul
if errorlevel 1 (
    netsh advfirewall firewall add rule name="Ray_LLM_8000" dir=in action=allow protocol=TCP localport=8000 >nul
)

netsh advfirewall firewall show rule name="Ray_LLM_8001" >nul
if errorlevel 1 (
    netsh advfirewall firewall add rule name="Ray_LLM_8001" dir=in action=allow protocol=TCP localport=8001 >nul
)

:: =========================================================
::  3. PREPARE WSL ENVIRONMENT
:: =========================================================
echo [4/4] Deploying vLLM_Api Package...

:: We copy the ENTIRE vLLM_Api folder to WSL to preserve package structure
:: This allows relative imports (from . import config) to work correctly

:: 1. Create parent directory
wsl -e bash -c "echo %WSL_PASSWORD% | sudo -S mkdir -p /cluster/llm/rayvllm"
wsl -e bash -c "echo %WSL_PASSWORD% | sudo -S chmod -R 777 /cluster/llm"

:: 2. Copy the current folder (vLLM_Api) to /cluster/llm/rayvllm/
:: We use rsync or cp. cp -r is simpler.
:: We assume the script is running from inside vLLM_Api, so %~dp0 is the path.
:: We need to convert Windows path to WSL path for the source.
:: Simple hack: /mnt/d/...

echo      Copying project files...
:: Remove old version to ensure clean state
wsl -e bash -c "rm -rf /cluster/llm/rayvllm/vLLM_Api"

:: Copy new version
:: Note: We use 'cp -r' from the mounted drive. 
:: We need to handle spaces in the path "Multi-PC Server".
wsl -e bash -c "cp -r '/mnt/d/AI_Tools/Multi-PC Server/vLLM_Api' /cluster/llm/rayvllm/"

:: 3. Fix permissions and line endings for the shell script
wsl -e bash -c "chmod +x /cluster/llm/rayvllm/vLLM_Api/host_start_vllm.sh"
wsl -e bash -c "sed -i 's/\r$//' /cluster/llm/rayvllm/vLLM_Api/host_start_vllm.sh"

:: =========================================================
::  4. LAUNCH vLLM SERVER
:: =========================================================
echo.
echo ============================================
echo   Launching vLLM Server...
echo   Connecting to Ray Head at: %WIN_IP%:6379
echo ============================================
echo.

:: We execute the script from within the package folder
wsl -e bash -c "export WSL_PASSWORD=%WSL_PASSWORD% && export HOST_LAN_IP=%WIN_IP% && export RAY_ADDRESS=%WIN_IP%:6379 && /cluster/llm/rayvllm/vLLM_Api/host_start_vllm.sh"

echo.
echo Server Stopped.
pause
exit /b 0
