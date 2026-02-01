@echo off
setlocal enabledelayedexpansion
title GLM-4.6 Worker Node (Final Fixed)
color 0B

:: =========================================================
::  USER CONFIGURATION
:: =========================================================
set HOST_IP=192.168.1.3
set WSL_PASSWORD=6162

:: =========================================================
:: STEP 0: Auto-Elevate
:: =========================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process '%~dpnx0' -Verb RunAs"
    exit /b
)

echo ============================================
echo    Starting Worker Node (Final)
echo ============================================
echo.

:: ---------------------------------------------------------
:: STEP 1: Detect Network
:: ---------------------------------------------------------
echo [1/3] Detecting Network...

for /f "usebackq tokens=*" %%A in (`powershell -Command "(Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -ne $null -and $_.NetAdapter.Status -eq 'Up' } | Select-Object -First 1).IPv4Address.IPAddress"`) do set WORKER_LAN_IP=%%A
for /f "usebackq tokens=1" %%B in (`wsl hostname -I`) do set WORKER_WSL_IP=%%B
set WORKER_WSL_IP=%WORKER_WSL_IP: =%

echo      Worker IP: %WORKER_LAN_IP%
echo      Target Host: %HOST_IP%
echo.

:: ---------------------------------------------------------
:: STEP 2: Configure Bridge & Firewall
:: ---------------------------------------------------------
echo [2/3] Configuring Network...

netsh interface portproxy reset >nul
netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=6379 connectaddress=%WORKER_WSL_IP% connectport=6379
netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=8265 connectaddress=%WORKER_WSL_IP% connectport=8265
netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=10001 connectaddress=%WORKER_WSL_IP% connectport=10001

for /L %%i in (10002,1,10010) do (
   netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=%%i connectaddress=%WORKER_WSL_IP% connectport=%%i >nul
)

:: Firewall Rules (Corrected Syntax)
netsh advfirewall firewall add rule name="Ray_Worker_Main" dir=in action=allow protocol=TCP localport=6379 profile=any >nul
netsh advfirewall firewall add rule name="Ray_Worker_Dash" dir=in action=allow protocol=TCP localport=8265 profile=any >nul
netsh advfirewall firewall add rule name="Ray_Worker_Obj" dir=in action=allow protocol=TCP localport=10001 profile=any >nul

for /L %%i in (10002,1,10010) do (
    netsh advfirewall firewall add rule name="Ray_Worker_Range_%%i" dir=in action=allow protocol=TCP localport=%%i profile=any >nul
)

echo      [OK] Bridge & Firewall Ready.
echo.

:: ---------------------------------------------------------
:: STEP 3: Launch Worker
:: ---------------------------------------------------------
set SCRIPT_DIR=%~dp0
set LOCAL_SH=%SCRIPT_DIR%worker_start.sh

echo [3/3] Launching Worker...

wsl -e bash -c "echo %WSL_PASSWORD% | sudo -S mkdir -p /cluster/llm/rayvllm"
wsl -e bash -c "echo %WSL_PASSWORD% | sudo -S chmod -R 777 /cluster/llm"

type "%LOCAL_SH%" | wsl -e bash -c "cat > /cluster/llm/rayvllm/worker_start.sh"
wsl -e bash -c "sed -i 's/\r$//' /cluster/llm/rayvllm/worker_start.sh"
wsl -e bash -c "chmod +x /cluster/llm/rayvllm/worker_start.sh"

echo =======================================================
echo  Target: %HOST_IP%
echo =======================================================
echo.

wsl -e bash -c "export RAY_HEAD_IP=%HOST_IP% && export MY_LAN_IP=%WORKER_LAN_IP% && export WSL_PASSWORD=%WSL_PASSWORD% && /cluster/llm/rayvllm/worker_start.sh"

echo.
echo Worker Stopped.
pause