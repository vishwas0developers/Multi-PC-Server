@echo off
title GLM-4.6 Host PC Verification
color 0E

echo ====================================
echo GLM-4.6 Host PC Verification
echo ====================================
echo.

echo Checking WSL2 installation...
wsl --list >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ WSL2 not found!
    echo Please run setup_host_pc.bat first
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

echo 'Checking HuggingFace cache...'
if [ -d '/mnt/d/Ai_Model/Huggingface' ]; then
    echo ✅ HuggingFace cache configured
else
    echo ❌ HuggingFace cache not configured!
    exit 1
fi

echo 'Checking startup script...'
if [ -f '/cluster/llm/rayvllm/start_api_server.sh' ]; then
    echo ✅ Host startup script found
else
    echo ❌ Host startup script not found!
    exit 1
fi

echo.
echo ====================================
echo ✅ Host PC Setup Complete!
echo ====================================
"

if %errorlevel% neq 0 (
    echo.
    echo ❌ Some components missing. Please run setup_host_pc.bat
    pause
    exit /b 1
)

echo.
echo Host PC is ready for GLM-4.6!
echo You can now run: start_host_server.bat
echo.
pause