#!/bin/bash
set -e
source "/cluster/llm/rayvllm/bin/activate"

# --- 1. IP CONFIGURATION ---
if [ -z "$HOST_LAN_IP" ]; then
    echo "[WARNING] IP not passed from Windows. Fallback to detection."
    HOST_LAN_IP=$(ip route get 1 | awk '{print $7;exit}')
fi

echo "---------------------------------------------"
echo "Host Using IP: $HOST_LAN_IP"
echo "---------------------------------------------"

# --- 2. HOSTS FILE FIX ---
CURRENT_HOSTNAME=$(hostname)
SUDO="echo $WSL_PASSWORD | sudo -S"

# Remove 127.0.1.1 loopback mapping
$SUDO sed -i "/127.0.1.1/d" /etc/hosts

# Ensure correct IP mapping exists
if ! grep -q "$HOST_LAN_IP $CURRENT_HOSTNAME" /etc/hosts; then
    echo "$HOST_LAN_IP $CURRENT_HOSTNAME" | $SUDO tee -a /etc/hosts >/dev/null
fi

# --- 3. RAY CONFIG (The Fix) ---
export RAY_memory_monitor_refresh_ms=0
export VLLM_HOST_IP="$HOST_LAN_IP"
export RAY_NODE_IP_ADDRESS="$HOST_LAN_IP"
export RAY_gcs_rpc_server_reconnect_timeout_s=60

# Force GLOO to use the correct IP
export GLOO_SOCKET_IFNAME="eth0"
export GLOO_SOCKET_IP="$HOST_LAN_IP"

ray stop --force >/dev/null 2>&1 || true

echo "[INFO] Starting Ray Head..."
ray start --head \
  --node-ip-address=$HOST_LAN_IP \
  --port=6379 \
  --dashboard-host=0.0.0.0 \
  --dashboard-port=8265 \
  --disable-usage-stats \
  --block