@echo off
setlocal enabledelayedexpansion
title Ray Host Server (Native Mirrored)
color 0A

:: =========================================================
::  USER CONFIGURATION
:: =========================================================
set WSL_PASSWORD=6162

:: =========================================================
:: STEP 0: Auto-Elevate
:: =========================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~dpnx0' -Verb RunAs"
    exit /b
)

echo ============================================
echo    Starting Ray Host (Native Mirrored)
echo ============================================
echo.

:: ---------------------------------------------------------
:: STEP 1: Detect Network
:: ---------------------------------------------------------
echo [1/4] Detecting Network...
for /f "usebackq tokens=*" %%A in (`powershell -Command "(Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -ne $null -and $_.NetAdapter.Status -eq 'Up' } | Select-Object -First 1).IPv4Address.IPAddress"`) do set WIN_IP=%%A

if "%WIN_IP%"=="" (
    echo [ERROR] No Windows IP found.
    pause
    exit /b
)
echo      Host IP: %WIN_IP%

:: ---------------------------------------------------------
:: STEP 2: GET WSL IP AND CONFIGURE PORT PROXY
:: ---------------------------------------------------------
echo [2/4] Configuring Port Proxy...

:: Get WSL IP
for /f "usebackq tokens=1" %%B in (`wsl hostname -I`) do set WSL_IP=%%B
set WSL_IP=%WSL_IP: =%

:: Remove old bridges
netsh interface portproxy reset >nul

:: Add new port proxy rules
netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=6379 connectaddress=%WSL_IP% connectport=6379 >nul
netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=8265 connectaddress=%WSL_IP% connectport=8265 >nul
netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=8000 connectaddress=%WSL_IP% connectport=8000 >nul
netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=10001 connectaddress=%WSL_IP% connectport=10001 >nul

for /L %%i in (10002,1,10010) do (
   netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=%%i connectaddress=%WSL_IP% connectport=%%i >nul
)

echo      [OK] Port Proxy Configured (WSL IP: %WSL_IP%).

:: ---------------------------------------------------------
:: STEP 3: Configure Firewall
:: ---------------------------------------------------------
echo [3/4] Configuring Firewall...
powershell -Command "Remove-NetFirewallRule -DisplayName 'Ray_Native_Allow' -ErrorAction SilentlyContinue"
powershell -Command "New-NetFirewallRule -DisplayName 'Ray_Native_Allow' -Direction Inbound -LocalPort 6379,8265,8000,10000-60000 -Protocol TCP -Action Allow -Profile Any"
echo      [OK] Firewall Ports Opened.

:: ---------------------------------------------------------
:: STEP 4: Launch Host
:: ---------------------------------------------------------
set SCRIPT_DIR=%~dp0
set LOCAL_SH=%SCRIPT_DIR%host_start_ray.sh

echo [4/4] Launching Host...

wsl -e bash -c "echo %WSL_PASSWORD% | sudo -S mount -o remount,size=12G /dev/shm" 2>nul
wsl -e bash -c "echo %WSL_PASSWORD% | sudo -S ip addr add %WIN_IP%/32 dev eth0 2>/dev/null || true"

type "%LOCAL_SH%" | wsl -e bash -c "cat > /cluster/llm/rayvllm/host_start_ray.sh && chmod +x /cluster/llm/rayvllm/host_start_ray.sh"

echo.
echo =======================================================
echo  HOST IP: %WIN_IP%
echo =======================================================
echo  NOTE: Access Dashboard at http://localhost:8265
echo =======================================================
echo.

wsl -e bash -c "export HOST_LAN_IP=%WIN_IP% && export WSL_PASSWORD=%WSL_PASSWORD% && /cluster/llm/rayvllm/host_start_ray.sh"

pause