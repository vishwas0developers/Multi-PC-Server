#!/bin/bash
set -e

# ============================================================
#     vLLM Local Tester (Port 8005) - FIXED FOR MIRRORED WSL2
# ============================================================

MODEL_DIR="/mnt/d/Ai_Model/Huggingface/Models/models--TinyLlama--TinyLlama-1.1B-Chat-v1.0"

source /cluster/llm/rayvllm/bin/activate
SUDO="echo $WSL_PASSWORD | sudo -S"

echo "---------------------------------------------"
echo "Windows IP Provided: $WIN_IP"
echo "---------------------------------------------"

# --- FIX: Bind Windows LAN IP into WSL (Mandatory) ---
echo "[INFO] Mapping Windows IP into WSL..."
$SUDO ip addr add $WIN_IP/32 dev eth0 2>/dev/null || true

# --- 1. CLEANUP (Port 8005) ---
echo "---------------------------------------------"
echo "Cleaning up Port 8005..."
$SUDO fuser -k -9 8005/tcp >/dev/null 2>&1 || true
ray stop --force >/dev/null 2>&1 || true
sleep 2
echo "[OK] Port ready."

# --- 2. Check Model Path ---
echo "Checking Model Path..."
if [ -d "$MODEL_DIR" ]; then
    echo "[OK] Found model: $MODEL_DIR"
else
    echo "[ERROR] Model path not found!"
    exit 1
fi

echo
echo "Starting vLLM on Local GPU (TP=1)..."
echo "---------------------------------------------"
echo

# --- 3. LAUNCH vLLM ---
python3 -m vllm.entrypoints.openai.api_server \
    --model "$MODEL_DIR" \
    --served-model-name tiny-llama-chat \
    --host 0.0.0.0 \
    --port 8005 \
    --tensor-parallel-size 1 \
    --gpu-memory-utilization 0.8 \
    --max-model-len 2048 \
    --trust-remote-code \
    --disable-log-requests
