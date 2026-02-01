@echo off
setlocal enabledelayedexpansion
title GLM-4.6 Host Server (Final IP Force)
color 0A

:: =========================================================
::  USER CONFIGURATION (Set your WSL Password here)
:: =========================================================
:: Niche "123456" ki jagah apna WSL Ubuntu ka password likhein
set WSL_PASSWORD=6162

:: =========================================================
:: STEP 0: Auto-Request Administrator Privileges
:: =========================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~dpnx0' -Verb RunAs"
    exit /b
)

echo ============================================
echo    Starting Host Server (Force LAN IP)
echo ============================================
echo.

:: ---------------------------------------------------------
:: STEP 1: Detect IPs (Windows LAN + WSL Internal)
:: ---------------------------------------------------------
echo [1/4] Detecting Network Configuration...

:: Get Windows LAN IP
for /f "usebackq tokens=*" %%A in (`powershell -Command "(Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -ne $null -and $_.NetAdapter.Status -eq 'Up' } | Select-Object -First 1).IPv4Address.IPAddress"`) do set WIN_IP=%%A

:: Get WSL Internal IP (Dynamic)
for /f "usebackq tokens=1" %%B in (`wsl hostname -I`) do set WSL_IP=%%B
set WSL_IP=%WSL_IP: =%

if "%WIN_IP%"=="" (
    echo ERROR: Could not detect Windows IP.
    pause
    exit /b
)

echo      Windows LAN IP : %WIN_IP%
echo      WSL Internal IP: %WSL_IP%
echo.

:: ---------------------------------------------------------
:: STEP 2: Configure Network Bridge (Windows -> WSL)
:: ---------------------------------------------------------
echo [2/4] Configuring Port Forwarding...

netsh interface portproxy reset >nul

:: Forward Ray Essential Ports
netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=6379 connectaddress=%WSL_IP% connectport=6379
netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=8265 connectaddress=%WSL_IP% connectport=8265
netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=8000 connectaddress=%WSL_IP% connectport=8000
netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=10001 connectaddress=%WSL_IP% connectport=10001

:: Forward Object Manager Range (Critical for Model Transfer - Same as Worker)
for /L %%i in (10002,1,10010) do (
   netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=%%i connectaddress=%WSL_IP% connectport=%%i >nul
)

echo      [OK] Bridge updated.
echo.

:: ---------------------------------------------------------
:: STEP 3: Configure Firewall
:: ---------------------------------------------------------
echo [3/4] Configuring Firewall...

:: Main Ports
set PORTS=8265 6379 8000 10001
for %%P in (%PORTS%) do (
    netsh advfirewall firewall add rule name="Ray_Host_%%P" dir=in action=allow protocol=TCP localport=%%P >nul
)

:: Object Manager Range
for /L %%i in (10002,1,10010) do (
    netsh advfirewall firewall add rule name="Ray_Host_Object_%%i" dir=in action=allow protocol=TCP localport=%%i >nul
)

echo      [OK] Firewall ports open.
echo.

:: ---------------------------------------------------------
:: STEP 4: Prepare & Run Script in WSL (IP Aliasing)
:: ---------------------------------------------------------
set SCRIPT_DIR=%~dp0
set LOCAL_SH=%SCRIPT_DIR%host_start_ray.sh

if not exist "%LOCAL_SH%" (
    echo ERROR: host_start_ray.sh missing!
    pause
    exit /b
)

echo [4/4] Preparing WSL Environment...

:: --- AUTO SUDO MAGIC HERE ---
wsl -e bash -c "echo %WSL_PASSWORD% | sudo -S mkdir -p /cluster/llm/rayvllm"
wsl -e bash -c "echo %WSL_PASSWORD% | sudo -S chmod -R 777 /cluster/llm"

:: --- THE MAGIC TRICK (SAME AS WORKER) ---
:: We add the Windows LAN IP inside WSL so Ray accepts it
echo      Adding IP Alias (%WIN_IP%) inside WSL...
wsl -e bash -c "echo %WSL_PASSWORD% | sudo -S ip addr add %WIN_IP%/32 dev eth0 2>/dev/null || true"

echo      Copying startup script...
type "%LOCAL_SH%" | wsl -e bash -c "cat > /cluster/llm/rayvllm/host_start_ray.sh"
wsl -e bash -c "sed -i 's/\r$//' /cluster/llm/rayvllm/host_start_ray.sh"
wsl -e bash -c "chmod +x /cluster/llm/rayvllm/host_start_ray.sh"

echo.
echo =======================================================
echo  DASHBOARD URL: http://%WIN_IP%:8265
echo  WORKER CMD:    ray start --address=%WIN_IP%:6379
echo =======================================================
echo Launching Ray Head inside WSL...
echo (Do NOT close this window - Minimize it)
echo.

:: Pass WIN_IP as HOST_LAN_IP and Password to the script
wsl -e bash -c "export HOST_LAN_IP=%WIN_IP% && export WSL_PASSWORD=%WSL_PASSWORD% && /cluster/llm/rayvllm/host_start_ray.sh"

echo.
echo Server Stopped.
pause