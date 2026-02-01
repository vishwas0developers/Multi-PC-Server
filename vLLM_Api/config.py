import os

# vLLM Server Configuration
# Default to localhost if not specified in environment variables
VLLM_HOST = os.getenv("VLLM_HOST", "localhost")
VLLM_PORT = os.getenv("VLLM_PORT", "8001")
VLLM_PROTOCOL = os.getenv("VLLM_PROTOCOL", "http")

# Construct the base URL
# Example: http://localhost:8000/v1
VLLM_BASE_URL = f"{VLLM_PROTOCOL}://{VLLM_HOST}:{VLLM_PORT}/v1"

# API Key (vLLM usually uses "EMPTY" for local servers, but can be configured)
VLLM_API_KEY = os.getenv("VLLM_API_KEY", "EMPTY")

# Model Name (Optional default, can be overridden in functions)
DEFAULT_MODEL = os.getenv("VLLM_MODEL", "TinyLlama/TinyLlama-1.1B-Chat-v1.0")
