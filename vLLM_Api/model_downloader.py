import os
import sys
from huggingface_hub import snapshot_download

# Map Windows path D:\Ai_Model\Huggingface to WSL path
# Assuming standard WSL mount point
HF_CACHE_DIR_WSL = "/mnt/d/Ai_Model/Huggingface"

def ensure_model_downloaded(model_name: str):
    """
    Checks if the model is available, and if not, downloads it to the specified directory.
    """
    print(f"--- Checking Model: {model_name} ---")
    print(f"Target Cache Directory: {HF_CACHE_DIR_WSL}")
    
    # Set the environment variable for HF Hub
    os.environ["HF_HOME"] = HF_CACHE_DIR_WSL
    
    try:
        # snapshot_download will check cache first and only download if needed
        # It returns the path to the folder
        path = snapshot_download(repo_id=model_name, cache_dir=HF_CACHE_DIR_WSL)
        print(f"✅ Model available at: {path}")
        return path
    except Exception as e:
        print(f"❌ Failed to download model: {e}")
        # We don't exit here, we let the caller decide (vLLM might fail later)
        raise e
