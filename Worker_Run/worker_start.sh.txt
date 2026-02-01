#!/bin/bash
set -e

# Configuration
VENV="/cluster/llm/rayvllm"
source "$VENV/bin/activate"

# Auto-Sudo Setup
if [ -z "$WSL_PASSWORD" ]; then
    echo "[ERROR] Password not received."
    exit 1
fi
SUDO="echo $WSL_PASSWORD | sudo -S"

echo "---------------------------------------------"
echo "       GLM-4.6 Worker Setup"
echo "---------------------------------------------"

# Fix for Shared Memory (Prevents Raylet Crash)
if [ -d "/dev/shm" ]; then
    echo "[INFO] Remounting /dev/shm to prevent memory crashes..."
    $SUDO mount -o remount,size=10G /dev/shm || true
fi

# 1. ADD FAKE IP
if ! ip addr show eth0 | grep -q "$MY_LAN_IP"; then
    echo "[INFO] Adding IP Alias $MY_LAN_IP to WSL..."
    $SUDO ip addr add $MY_LAN_IP/32 dev eth0
else
    echo "[INFO] IP Alias $MY_LAN_IP already exists."
fi

echo "---------------------------------------------"
echo "My Forced IP:   $MY_LAN_IP"
echo "Target Host:    $RAY_HEAD_IP"
echo "---------------------------------------------"

# 2. Stop old processes
ray stop --force >/dev/null 2>&1 || true

# 3. Start Worker (FIXED PORTS)
# Humne yahan specific ports add kiye hain jo Windows bridge se match karte hain
echo "[INFO] Connecting to Cluster..."

ray start \
  --address=$RAY_HEAD_IP:6379 \
  --node-ip-address=$MY_LAN_IP \
  --dashboard-host=0.0.0.0 \
  --object-manager-port=10002 \
  --node-manager-port=10003 \
  --min-worker-port=10004 \
  --max-worker-port=10010 \
  --disable-usage-stats \
  --block