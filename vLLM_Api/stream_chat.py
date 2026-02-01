from typing import List, Dict, Generator
from .client import get_client
from .config import DEFAULT_MODEL

def stream_chat_completion(
    messages: List[Dict[str, str]],
    model: str = DEFAULT_MODEL,
    temperature: float = 0.7,
    max_tokens: int = 1024
) -> Generator[str, None, None]:
    """
    Sends a streaming chat completion request to the vLLM server.

    Args:
        messages: A list of message dictionaries.
        model: The model name to use.
        temperature: Sampling temperature.
        max_tokens: Maximum tokens to generate.

    Yields:
        Chunks of generated text content as they arrive.
    """
    client = get_client()
    
    stream = client.chat.completions.create(
        model=model,
        messages=messages,
        temperature=temperature,
        max_tokens=max_tokens,
        stream=True
    )

    for chunk in stream:
        if chunk.choices[0].delta.content is not None:
            yield chunk.choices[0].delta.content
