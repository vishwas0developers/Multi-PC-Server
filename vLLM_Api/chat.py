from typing import List, Dict, Any, Union
from .client import get_client
from .config import DEFAULT_MODEL

def chat_completion(
    messages: List[Dict[str, str]],
    model: str = DEFAULT_MODEL,
    temperature: float = 0.7,
    max_tokens: int = 1024,
    return_full_response: bool = False
) -> Union[str, Any]:
    """
    Sends a chat completion request to the vLLM server.

    Args:
        messages: A list of message dictionaries (e.g., [{"role": "user", "content": "Hello"}]).
        model: The model name to use.
        temperature: Sampling temperature.
        max_tokens: Maximum tokens to generate.
        return_full_response: If True, returns the full API response object. If False, returns just the content string.

    Returns:
        The generated text content or the full response object.
    """
    client = get_client()
    
    response = client.chat.completions.create(
        model=model,
        messages=messages,
        temperature=temperature,
        max_tokens=max_tokens,
        stream=False
    )

    if return_full_response:
        return response
    
    return response.choices[0].message.content
