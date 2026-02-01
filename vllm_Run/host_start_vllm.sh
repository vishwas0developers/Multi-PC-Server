#!/bin/bash
set -e

echo "============================================="
echo "     GLM-4.6 Distributed vLLM Launcher"
echo "============================================="
echo

source /cluster/llm/rayvllm/bin/activate

HOST_IP=$(hostname -I | awk '{print $1}')
echo "Host WSL IP: $HOST_IP"
echo

echo "Starting Distributed vLLM..."

python3 -m vllm.entrypoints.openai.api_server \
    --model zai-org/GLM-4.6 \
    --host 0.0.0.0 \
    --port 8000 \
    --gpu-memory-utilization 0.45 \
    --tensor-parallel-size 3 \
    --max-model-len 32768 \
    --swap-space 0 \
    --served-model-name glm-4-6

echo
echo "============================================="
echo "Distributed vLLM Running at: http://$HOST_IP:8000/v1"
echo "============================================="
