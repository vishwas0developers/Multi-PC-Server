@echo off
setlocal
title Ray LLM Serve - GLM-4.6 Cluster
color 0A

echo ============================================
echo     GLM-4.6 Ray Serve Deployment
echo     Mode: Native Ray Serve (Production)
echo ============================================
echo.

:: Configuration
set HOST_IP=192.168.1.3
set SCRIPT_DIR=%~dp0
set TARGET_DIR=/cluster/llm/rayvllm

:: Files to copy
set FILE_APP=%SCRIPT_DIR%serve_glm.py
set FILE_MGR=%SCRIPT_DIR%deploy_manager.py

IF NOT EXIST "%FILE_APP%" (
    echo ERROR: serve_glm.py not found.
    pause
    exit /b 1
)

echo [1/4] Copying scripts to WSL Cluster path...
:: Copy Application
type "%FILE_APP%" | wsl -e bash -c "cat > %TARGET_DIR%/serve_glm.py"
wsl -e bash -c "sed -i 's/\r$//' %TARGET_DIR%/serve_glm.py"

:: Copy Manager
type "%FILE_MGR%" | wsl -e bash -c "cat > %TARGET_DIR%/deploy_manager.py"
wsl -e bash -c "sed -i 's/\r$//' %TARGET_DIR%/deploy_manager.py"

echo [2/4] Installing missing dependencies (pyarrow)...
:: Ye line pyarrow install karegi jo error de raha tha
wsl -e bash -c "source %TARGET_DIR%/bin/activate && pip install pyarrow"

echo [3/4] Verifying Ray connection...
wsl -e bash -c "source %TARGET_DIR%/bin/activate && ray status" > nul
if %errorlevel% neq 0 (
    echo WARNING: Ray Cluster might not be running!
    echo Please ensure 'ray start --head' is running on this machine.
    echo.
    pause
)

echo [4/4] Launching Service...
echo.
echo ========================================================
echo NOTE: First run usually takes 2-3 minutes to initialize
echo the distributed workers. Please wait.
echo ========================================================
echo.

:: Run the Python Manager inside the virtual environment
wsl -e bash -c "source %TARGET_DIR%/bin/activate && python3 %TARGET_DIR%/deploy_manager.py"

pause