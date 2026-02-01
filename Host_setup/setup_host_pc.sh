#!/bin/bash
set -e

echo "==============================================="
echo " GLM-4.6 Host Setup + Verification (WSL Side) "
echo "==============================================="
echo

VENV_PATH="/cluster/llm/rayvllm"
START_SCRIPT="$VENV_PATH/start_api_server.sh"
NEED_INSTALL=0
NEED_PIP=0

echo "[STEP] Checking /cluster/llm directory..."
if [ ! -d "/cluster/llm" ]; then
    echo "[INFO] Creating /cluster/llm ..."
    sudo mkdir -p /cluster/llm
    sudo chown -R $USER:$USER /cluster
else
    echo "[OK] /cluster/llm found."
fi

echo
echo "[STEP] Checking virtual environment..."
if [ ! -d "$VENV_PATH" ]; then
    echo "[INFO] Virtual environment missing. Full install required."
    NEED_INSTALL=1
else
    echo "[OK] Virtual environment found."
fi

if [ "$NEED_INSTALL" -eq 1 ]; then
    echo "[STEP] Installing system packages..."
    sudo apt-get update
    sudo apt-get install -y python3 python3-venv python3-pip python3-dev build-essential

    echo "[STEP] Creating virtual environment..."
    python3 -m venv "$VENV_PATH"
fi

echo "[STEP] Activating virtual environment..."
source "$VENV_PATH/bin/activate"

echo
echo "[STEP] Checking Ray..."
if ! command -v ray >/dev/null 2>&1; then
    echo "[WARN] Ray missing; will install."
    NEED_PIP=1
else
    echo "[OK] Ray installed: $(ray --version)"
fi

echo "[STEP] Checking vLLM..."
if ! python -c "import vllm" >/dev/null 2>&1; then
    echo "[WARN] vLLM missing; will install."
    NEED_PIP=1
else
    echo "[OK] vLLM installed: $(python -c 'import vllm; print(vllm.__version__)')"
fi

if [ "$NEED_PIP" -eq 1 ]; then
    echo "[STEP] Installing Ray + vLLM..."
    pip install --upgrade pip
    pip install "ray[default,serve]" vllm --extra-index-url https://download.pytorch.org/whl/cu128
else
    echo "[OK] Python dependencies already installed."
fi

echo
echo "[STEP] Checking HuggingFace cache..."
if ! grep -q "HF_HOME" ~/.bashrc; then
    echo "export HF_HOME=/mnt/d/Ai_Model/Huggingface" >> ~/.bashrc
    echo "export HUGGINGFACE_HUB_CACHE=/mnt/d/Ai_Model/Huggingface/cache" >> ~/.bashrc
    echo "[INFO] Added HF_HOME to ~/.bashrc"
else
    echo "[OK] HuggingFace cache vars already set."
fi

echo
echo "[STEP] Checking start_api_server.sh..."
if [ ! -f "$START_SCRIPT" ]; then
    echo "[INFO] Creating default start_api_server.sh..."
cat > "$START_SCRIPT" << 'EOF'
#!/bin/bash
set -e
VENV="/cluster/llm/rayvllm"
source "$VENV/bin/activate"

HOST_IP=$(hostname -I | awk '{print $1}')
PORT=8000
RAYPORT=6379

ray stop || true
ray start --head --node-ip-address="$HOST_IP" --port="$RAYPORT" --dashboard-host=0.0.0.0 --dashboard-port=8265

python -m vllm.entrypoints.openai.api_server \
  --host 0.0.0.0 \
  --port "$PORT" \
  --model zai-org/GLM-4.6 \
  --tensor-parallel-size=3 \
  --pipeline-parallel-size=1 \
  --served-model-name glm-4-6
EOF

    chmod +x "$START_SCRIPT"
    echo "[OK] start_api_server.sh created."
else
    echo "[OK] start_api_server.sh exists."
fi

echo
echo "============ HOST SETUP SUMMARY ============"
if [ "$NEED_INSTALL" -eq 0 ] && [ "$NEED_PIP" -eq 0 ]; then
    echo "[RESULT] Host PC was already configured. No installation performed."
elif [ "$NEED_INSTALL" -eq 1 ]; then
    echo "[RESULT] Fresh Host PC installation completed."
else
    echo "[RESULT] Missing components were installed."
fi
echo "==========================================="

exit 0
