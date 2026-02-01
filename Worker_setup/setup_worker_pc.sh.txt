#!/bin/bash
set -e

echo "==============================================="
echo " GLM-4.6 Worker Setup + Verification (WSL Side) "
echo "==============================================="
echo

VENV_PATH="/cluster/llm/rayvllm"
WORKER_SCRIPT="$VENV_PATH/worker_start.sh"
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
    echo "[INFO] Virtual environment missing. Full worker installation required."
    NEED_INSTALL=1
else
    echo "[OK] Virtual environment found."
fi

if [ "$NEED_INSTALL" -eq 1 ]; then
    echo "[STEP] Installing required system packages..."
    sudo apt-get update
    sudo apt-get install -y python3 python3-venv python3-pip python3-dev build-essential

    echo "[STEP] Creating virtual environment..."
    python3 -m venv "$VENV_PATH"
fi

echo "[STEP] Activating virtual environment..."
source "$VENV_PATH/bin/activate"

echo
echo "[STEP] Checking Ray client..."
if ! command -v ray >/dev/null 2>&1; then
    echo "[WARN] Ray missing; will install."
    NEED_PIP=1
else
    echo "[OK] Ray installed: $(ray --version)"
fi

echo "[STEP] Checking vLLM (worker-friendly) package..."
if ! python -c "import vllm" >/dev/null 2>&1; then
    echo "[WARN] vLLM missing; will install."
    NEED_PIP=1
else
    echo "[OK] vLLM installed: $(python -c 'import vllm; print(vllm.__version__)')"
fi

if [ "$NEED_PIP" -eq 1 ]; then
    echo "[STEP] Installing Ray + vLLM for Worker..."
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
echo "[STEP] Checking worker_start.sh..."
if [ ! -f "$WORKER_SCRIPT" ]; then
    echo "[INFO] Creating worker_start.sh..."

cat > "$WORKER_SCRIPT" << 'EOF'
#!/bin/bash
set -e

VENV="/cluster/llm/rayvllm"
source "$VENV/bin/activate"

# Auto detect Worker IP
WORKER_IP=$(hostname -I | awk '{print $1}')

# Replace with Host PC LAN IP manually if needed (default placeholder)
RAY_HEAD_IP=192.168.1.100

echo "Starting Ray Worker Node..."
echo "Connecting to Host IP: $RAY_HEAD_IP"
echo "Worker IP: $WORKER_IP"

ray start --address=$RAY_HEAD_IP:6379 \
    --node-ip-address=$WORKER_IP \
    --block
EOF

    chmod +x "$WORKER_SCRIPT"
    echo "[OK] worker_start.sh created."
else
    echo "[OK] worker_start.sh exists."
fi

echo
echo "============ WORKER SETUP SUMMARY ============"
if [ "$NEED_INSTALL" -eq 0 ] && [ "$NEED_PIP" -eq 0 ]; then
    echo "[RESULT] Worker PC was already configured. No installation performed."
elif [ "$NEED_INSTALL" -eq 1 ]; then
    echo "[RESULT] Fresh Worker installation completed."
else
    echo "[RESULT] Missing components installed."
fi
echo "=============================================="

exit 0
