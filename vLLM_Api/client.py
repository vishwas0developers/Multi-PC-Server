from openai import OpenAI
from .config import VLLM_BASE_URL, VLLM_API_KEY

_client_instance = None

def get_client() -> OpenAI:
    """
    Returns a singleton instance of the OpenAI client configured for the vLLM server.
    """
    global _client_instance
    if _client_instance is None:
        _client_instance = OpenAI(
            base_url=VLLM_BASE_URL,
            api_key=VLLM_API_KEY,
        )
    return _client_instance
