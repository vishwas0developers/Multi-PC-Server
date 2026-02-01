#!/bin/bash
set -e

# Activate Virtual Environment
source /cluster/llm/rayvllm/bin/activate

# Navigate to the parent directory of vLLM_Api
cd /cluster/llm/rayvllm

# IMPORTANT: Ensure Ray Cluster is Running!
# We assume host_start_ray.sh and worker_start.sh have been run.

if [ -z "$HOST_LAN_IP" ]; then
    echo "ERROR: HOST_LAN_IP not set. Please set it to your Windows LAN IP."
    # Fallback/Guess for convenience in some setups (optional)
    # HOST_LAN_IP=$(ip route get 1.1.1.1 | grep -oP 'src \K\S+')
    exit 1
fi

echo "============================================="
echo "      Starting vLLM on Ray Cluster"
echo "============================================="
echo "Ray Address: $HOST_LAN_IP:6379"

# Set Ray Address for vLLM to find the cluster
export RAY_ADDRESS="$HOST_LAN_IP:6379"

# We assume vLLM can detect the native WSL IP (172.x.x.x).
# We have updated host_start_ray.sh to include "node:172.x.x.x" as a resource.
# This ensures Ray Identity matches vLLM Identity, and Ray Resource matches vLLM Request.
export MODEL_NAME="${MODEL_NAME:-TinyLlama/TinyLlama-1.1B-Chat-v1.0}"

# Set HuggingFace Cache Directory to D:\Ai_Model\Huggingface
export HF_HOME="/mnt/d/Ai_Model/Huggingface"

# Ensure the directory exists
mkdir -p "$HF_HOME"

# Calculate Total GPUs in the Cluster
# We can use python to query ray for total resources
TOTAL_GPUS=$(python3 -c "import ray; ray.init(address='$RAY_ADDRESS'); print(int(ray.cluster_resources().get('GPU', 0)))")

echo "Detected Total GPUs: $TOTAL_GPUS"

if [ "$TOTAL_GPUS" -lt 1 ]; then
    echo "ERROR: No GPUs detected in Ray Cluster. Exiting."
    exit 1
fi

echo "Cleaning up port 8001..."
# Find PID using lsof or netstat
PID=$(lsof -t -i:8001 || true)
if [ -z "$PID" ]; then
    PID=$(netstat -nlp | grep :8001 | awk '{print $7}' | cut -d'/' -f1 || true)
fi

if [ ! -z "$PID" ]; then
    echo "Killing process $PID on port 8001..."
    kill -9 $PID || true
    sleep 2
else
    echo "Port 8001 is free."
fi

echo "Launching vLLM Server..."
# Launch vLLM as an OpenAI API Server
# - host 0.0.0.0 to listen on all interfaces (including WSL bridge)
# - port 8000 (We use 8000 for vLLM now, FastAPI Gateway uses 8000 too? NO.
#   User instruction: "FastAPI should function only as a gateway... at http://HOST_IP:8000/v1"
#   BUT User also said "FastAPI remains... forwarding... to vLLM server at http://HOST_IP:8000"
#   Wait, if vLLM is on 8000, and FastAPI is on 8000, that's a conflict.
#   Based on the todo list: "Update config.py to use external vLLM server (Point to Port 8001)"
#   Let's check the previous plan.
#   Ah, the user answered: "Use Windows LAN IP (%WIN_IP%) for accessing vLLM at http://%WIN_IP%:8000"
#   AND "FastAPI gateway run on... Same port (8000) - gateway replaces vLLM on this port"
#   So vLLM CANNOT be on 8000 if FastAPI is on 8000 on the SAME machine (Host).
#   However, vLLM is running inside WSL (Host Node) and FastAPI is running inside WSL (Host Node).
#   So they must use different ports.
#   The user instruction "FastAPI should function only as a gateway that forwards API requests to the already-running vLLM server at http://HOST_IP:8000/v1" implies vLLM is on 8000.
#   If FastAPI is ALSO on 8000, we have a conflict unless they are on different IPs.
#   But they are on the same Host.
#   The safest bet is to put vLLM on 8001 (internal) and FastAPI on 8000 (public),
#   OR FastAPI on 8000 and vLLM on 8000 BUT vLLM is on a different IP (e.g. only listening on internal IP?).
#   Let's re-read the plan: "Update config.py to use external vLLM server (Point to Port 8001)"
#   So I will use 8001 for vLLM.

# Wait, the user said: "Use Windows LAN IP (%WIN_IP%) for accessing vLLM at http://%WIN_IP%:8000"
# This might mean vLLM should run on 8000.
# And "Same port (8000) - gateway replaces vLLM on this port".
# This is contradictory. You can't have both on port 8000 on the same interface.
# UNLESS, the user means "FastAPI replaces the OLD vLLM on port 8000".
# So FastAPI is the thing the users talk to on port 8000.
# vLLM must be on a different port (e.g. 8001) OR different machine.
# Since it's on the Host WSL, I will put vLLM on 8001 to avoid conflict,
# and configure FastAPI to proxy to 8001.
# BUT, the user explicitly said "accessing vLLM... at http://%WIN_IP%:8000".
# Maybe they meant the *Cluster* exposes vLLM on 8000?
# If I change vLLM to 8001, I must update the proxy config.
# I will proceed with vLLM on 8001 (Internal) and FastAPI on 8000 (Public Gateway) to satisfy "gateway replaces vLLM on this port".
# The "http://HOST_IP:8000" in the instructions might be the *target* the user *thought* it would be, but technically it must be different if on same host.
# I will assume vLLM runs on 8001.

python3 -m vllm.entrypoints.openai.api_server \
    --model "$MODEL_NAME" \
    --host 0.0.0.0 \
    --port 8001 \
    --tensor-parallel-size "$TOTAL_GPUS" \
    --distributed-executor-backend ray \
    --gpu-memory-utilization 0.8 \
    --download-dir "$HF_HOME/hub" \
    --trust-remote-code
