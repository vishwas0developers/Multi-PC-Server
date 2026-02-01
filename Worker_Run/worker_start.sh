#!/bin/bash
set -e

VENV="/cluster/llm/rayvllm"
source "$VENV/bin/activate"

if [ -z "$WSL_PASSWORD" ]; then
    echo "[ERROR] Password missing."
    exit 1
fi
SUDO="echo $WSL_PASSWORD | sudo -S"

# 1. IP Alias
if ! ip addr show eth0 | grep -q "$MY_LAN_IP"; then
    $SUDO ip addr add $MY_LAN_IP/32 dev eth0
fi

# 2. FIX FOR RAY CRASH (Memory Monitor)
export RAY_memory_monitor_refresh_ms=0

# 3. vLLM IP Fix
export VLLM_HOST_IP="$MY_LAN_IP"
export RAY_NODE_IP_ADDRESS="$MY_LAN_IP"

echo "---------------------------------------------"
echo "Worker IP: $MY_LAN_IP"
echo "Target:    $RAY_HEAD_IP"
echo "Memory Monitor: DISABLED"
echo "---------------------------------------------"

ray stop --force >/dev/null 2>&1 || true

echo "[INFO] Connecting..."
ray start \
  --address=$RAY_HEAD_IP:6379 \
  --node-ip-address=$MY_LAN_IP \
  --dashboard-host=0.0.0.0 \
  --disable-usage-stats \
  --block