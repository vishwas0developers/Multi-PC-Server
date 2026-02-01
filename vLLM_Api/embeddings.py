from typing import List, Union
from .client import get_client
from .config import DEFAULT_MODEL

def get_embeddings(
    input_text: Union[str, List[str]],
    model: str = DEFAULT_MODEL
) -> List[List[float]]:
    """
    Generates embeddings for the input text using the vLLM server.

    Args:
        input_text: A string or list of strings to embed.
        model: The model name to use.

    Returns:
        A list of embedding vectors (each vector is a list of floats).
    """
    client = get_client()
    
    # Ensure input is a list if it's a single string, for consistent handling
    # (Though the API handles both, returning a list of Data objects)
    if isinstance(input_text, str):
        input_text = [input_text]

    response = client.embeddings.create(
        model=model,
        input=input_text
    )

    # Extract embeddings from the response
    # response.data is a list of Embedding objects, each has an 'embedding' attribute
    return [data.embedding for data in response.data]
