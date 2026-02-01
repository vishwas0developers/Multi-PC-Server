@echo off
setlocal
title Start Distributed vLLM Engine
color 0A

echo ============================================
echo     Starting GLM-4.6 Distributed vLLM
echo ============================================
echo.

set SCRIPT_DIR=%~dp0
set SH_FILE=%SCRIPT_DIR%host_start_vllm.sh

IF NOT EXIST "%SH_FILE%" (
    echo ERROR: host_start_vllm.sh not found.
    pause
    exit /b 1
)

echo Found host_start_vllm.sh

echo Copying script to WSL...
type "%SH_FILE%" | wsl -e bash -c "cat > /cluster/llm/rayvllm/host_start_vllm.sh"
wsl -e bash -c "chmod +x /cluster/llm/rayvllm/host_start_vllm.sh"

echo Launching vLLM...
wsl -e bash -c "/cluster/llm/rayvllm/host_start_vllm.sh"

pause
exit /b 0
