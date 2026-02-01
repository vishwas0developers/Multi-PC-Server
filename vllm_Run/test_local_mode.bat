@echo off
setlocal enabledelayedexpansion
title Local Test (Host Only - Port 8005)
color 0E

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
echo    Starting vLLM (Port 8005)
echo ============================================
echo.

:: ---------------------------------------------------------
:: STEP 1: Detect Windows LAN IP
:: ---------------------------------------------------------
for /f "usebackq tokens=*" %%A in (`
    powershell -Command "(Get-NetIPConfiguration | 
    Where-Object { $_.IPv4DefaultGateway -ne $null -and $_.NetAdapter.Status -eq 'Up' } |
    Select-Object -First 1).IPv4Address.IPAddress"
`) do set WIN_IP=%%A

echo Detected Windows IP: %WIN_IP%
echo.

:: ---------------------------------------------------------
:: STEP 2: Configure Firewall (Port 8005)
:: ---------------------------------------------------------
echo Configuring Firewall for Port 8005...
powershell -Command "New-NetFirewallRule -DisplayName 'vLLM_API_8005' -Direction Inbound -LocalPort 8005 -Protocol TCP -Action Allow -Profile Any -ErrorAction SilentlyContinue"

:: ---------------------------------------------------------
:: STEP 3: Copy Script to WSL
:: ---------------------------------------------------------
set SCRIPT_DIR=%~dp0
set LOCAL_SH=%SCRIPT_DIR%host_test_local.sh

echo Copying script to WSL...
type "%LOCAL_SH%" | wsl -e bash -c "tr -d '\r' > /cluster/llm/rayvllm/host_test_local.sh && chmod +x /cluster/llm/rayvllm/host_test_local.sh"

:: ---------------------------------------------------------
:: STEP 4: Launch vLLM
:: ---------------------------------------------------------
echo.
echo =======================================================
echo  TEST MODE: Running on HOST GPU ONLY.
echo  Workers are IGNORED.
echo  API URL: http://%WIN_IP%:8005/v1
echo =======================================================
echo.

wsl -e bash -c "export WSL_PASSWORD=%WSL_PASSWORD% && export WIN_IP=%WIN_IP% && bash /cluster/llm/rayvllm/host_test_local.sh"

pause
