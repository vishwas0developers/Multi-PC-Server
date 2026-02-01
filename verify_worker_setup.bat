@echo off
title GLM-4.6 Worker PC Verification
color 0B

echo ====================================
echo GLM-4.6 Worker PC Verification
echo ====================================
echo.

echo Checking WSL2 installation...
wsl --list >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ WSL2 not found!
    echo Please run setup_worker_pc.bat first
    pause
    exit /b 1
) else (
    echo ✅ WSL2 found
)

echo.
echo Checking Ray and vLLM installation...
wsl -e bash -c "
echo 'Checking virtual environment...'
if [ -d '/cluster/llm/rayvllm' ]; then
    echo ✅ Virtual environment found
else
    echo ❌ Virtual environment not found!
    exit 1
fi

echo 'Checking Ray installation...'
source /cluster/llm/rayvllm/bin/activate
if command -v ray &> /dev/null; then
    echo ✅ Ray installed: $(ray --version)
else
    echo ❌ Ray not found!
    exit 1
fi

echo 'Checking vLLM installation...'
if python -c 'import vllm; print(vllm.__version__)' 2>/dev/null; then
    echo ✅ vLLM installed: $(python -c 'import vllm; print(vllm.__version__)')
else
    echo ❌ vLLM not found!
    exit 1
fi

echo 'Checking worker script...'
if [ -f '/cluster/llm/rayvllm/worker_start.sh' ]; then
    echo ✅ Worker startup script found
else
    echo ❌ Worker startup script not found!
    exit 1
fi

echo 'Checking Host IP configuration...'
if grep -q 'RAY_HEAD_IP=' /cluster/llm/rayvllm/worker_start.sh; then
    echo ✅ Host IP configuration found
    echo Current Host IP: $(grep 'RAY_HEAD_IP=' /cluster/llm/rayvllm/worker_start.sh | cut -d'=' -f2)
else
    echo ❌ Host IP not configured!
    exit 1
fi

echo.
echo ====================================
echo ✅ Worker PC Setup Complete!
echo ====================================
"

if %errorlevel% neq 0 (
    echo.
    echo ❌ Some components missing. Please run setup_worker_pc.bat
    pause
    exit /b 1
)

echo.
echo Worker PC is ready for GLM-4.6!
echo You can now run: start_worker_node.bat
echo.
echo Note: Make sure Host PC is running before starting worker
echo.
pause