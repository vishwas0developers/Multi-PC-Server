import sys
import os

# Add the parent directory to sys.path so we can import vLLM_Api
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

try:
    from vLLM_Api import check_health, chat_completion, stream_chat_completion, get_embeddings, get_client
    print("✅ Successfully imported vLLM_Api modules.")
except ImportError as e:
    print(f"❌ Failed to import vLLM_Api: {e}")
    sys.exit(1)

print("\n--- Testing Health Check ---")
try:
    is_healthy = check_health()
    print(f"Health Check Result: {is_healthy}")
    if not is_healthy:
        print("(Expected if server is not running)")
except Exception as e:
    print(f"❌ Health Check failed with unexpected error: {e}")

print("\n--- Testing Client Retrieval ---")
try:
    client = get_client()
    print(f"Client Base URL: {client.base_url}")
    print("✅ Client retrieved successfully.")
except Exception as e:
    print(f"❌ Failed to get client: {e}")

print("\n--- Verification Complete ---")
