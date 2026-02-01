#!/bin/bash
set -e

# Configuration
VENV="/cluster/llm/rayvllm"
source "$VENV/bin/activate"

# Auto-Sudo Setup (received from Bat file)
if [ -z "$WSL_PASSWORD" ]; then
    echo "[ERROR] Password not received."
    exit 1
fi
SUDO="echo $WSL_PASSWORD | sudo -S"

echo "============================================="
echo "      GLM-4.6 Host Ray Head (IP Fix)"
echo "============================================="

# 1. ADD FAKE IP (Double Check)
# Verify if the LAN IP is aliased. If not, try to add it again.
if ! ip addr show eth0 | grep -q "$HOST_LAN_IP"; then
    echo "[INFO] Adding IP Alias $HOST_LAN_IP to WSL..."
    $SUDO ip addr add $HOST_LAN_IP/32 dev eth0
else
    echo "[INFO] IP Alias $HOST_LAN_IP already exists."
fi

echo "---------------------------------------------"
echo "Host Advertising IP: $HOST_LAN_IP"
echo "---------------------------------------------"

# 2. Stop old processes
ray stop --force > /dev/null 2>&1 || true

# 3. Start Ray Head
# CRITICAL: We bind to the LAN IP ($HOST_LAN_IP)
# We use --dashboard-host=0.0.0.0 to allow viewing from Windows browser
echo "[INFO] Starting Ray Head..."

# Detect Native WSL IP
WSL_IP=$(hostname -I | awk '{print $1}')
echo "Adding custom resource for WSL IP: node:$WSL_IP"

# We add resources: {"node:$WSL_IP": 1.0} so vLLM can schedule on it if it detects WSL IP.
ray start --head \
  --node-ip-address=$HOST_LAN_IP \
  --port=6379 \
  --resources "{\"node:$WSL_IP\": 1.0}" \
  --dashboard-host=0.0.0.0 \
  --dashboard-port=8265 \
  --disable-usage-stats \
  --block