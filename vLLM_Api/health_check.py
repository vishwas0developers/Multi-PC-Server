import requests
from .config import VLLM_BASE_URL

# Helper to check if Ray Dashboard is responsive (simple TCP check or HTTP)
def check_ray_health() -> bool:
    """
    Checks if Ray Dashboard (port 8265) is reachable.
    """
    try:
        # Assuming Ray Dashboard is on the same host as configured, or localhost if not specified
        # But Ray might be on a different IP.
        # Let's trust that if vLLM is up, Ray is up.
        # But if we really want to check Ray specifically:
        resp = requests.get("http://127.0.0.1:8265", timeout=1)
        return resp.status_code == 200
    except:
        return False

def check_health() -> bool:
    """
    Checks if the vLLM server is reachable and healthy.
    Returns True if the server responds to a models list request, False otherwise.
    """
    try:
        # We use the models endpoint as a simple health check
        # A simple GET to /v1/models should return 200 OK
        response = requests.get(f"{VLLM_BASE_URL}/models", timeout=2)
        if response.status_code == 200:
            return True
        return False
    except requests.RequestException:
        return False

def get_server_status() -> dict:
    """
    Returns a more detailed status dictionary.
    """
    try:
        response = requests.get(f"{VLLM_BASE_URL}/models", timeout=2)
        if response.status_code == 200:
            return {"status": "online", "models": response.json()}
        return {"status": "error", "code": response.status_code}
    except requests.RequestException as e:
        return {"status": "offline", "error": str(e), "ray_status": "unknown"}
