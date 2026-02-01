import os
import glob
import json
import sys
import subprocess
import shutil
import time

# ================= CONFIGURATION =================
BASE_DIR = "/mnt/d/Ai_Model/Huggingface"
MODEL_ID = "zai-org/GLM-4.6"
HOST_IP = "192.168.1.3"
RAY_ADDRESS = f"{HOST_IP}:6379"
# =================================================

def find_model_path(base_dir, model_id):
    repo_path = os.path.join(base_dir, "hub", f"models--{model_id.replace('/', '--')}")
    snapshots_path = os.path.join(repo_path, "snapshots")
    
    if not os.path.exists(snapshots_path):
        print(f"[ERROR] Snapshots path not found: {snapshots_path}")
        return None
    
    subdirs = glob.glob(os.path.join(snapshots_path, "*"))
    if not subdirs:
        return None
    
    # Return the most recently modified folder
    return max(subdirs, key=os.path.getmtime)

def patch_config_json(model_path):
    """Forces tensor_parallel_size to 1 in config.json"""
    config_file = os.path.join(model_path, "config.json")
    try:
        with open(config_file, 'r') as f:
            config = json.load(f)
        
        updated = False
        # Force TP=1 to avoid 'Available GPUs' error
        if config.get('tensor_parallel_size') != 1:
            print(f"[PATCH] Fixing tensor_parallel_size in {config_file}")
            config['tensor_parallel_size'] = 1
            updated = True
            
        if config.get('world_size') != 1:
            config['world_size'] = 1
            updated = True

        if updated:
            with open(config_file, 'w') as f:
                json.dump(config, f, indent=2)
            print("[SUCCESS] Config patched.")
        else:
            print("[INFO] Config already correct.")
        return True
    except Exception as e:
        print(f"[ERROR] Failed to patch config: {e}")
        return False

def main():
    print("=== Ray Serve LLM Deployment Manager ===")
    
    # 1. Find Model
    model_path = find_model_path(BASE_DIR, MODEL_ID)
    if not model_path:
        print(f"[ERROR] Model not found in {BASE_DIR}. Please download it first.")
        sys.exit(1)
    
    print(f"[INFO] Target Model Path: {model_path}")

    # 2. Patch Config
    if not patch_config_json(model_path):
        sys.exit(1)

    # 3. Prepare Environment
    env = os.environ.copy()
    env["RAY_ADDRESS"] = RAY_ADDRESS
    env["VLLM_HOST_IP"] = HOST_IP
    env["TARGET_MODEL_PATH"] = model_path # Passing path to serve_glm.py
    
    # Working directory should be where the script is
    cwd = os.path.dirname(os.path.abspath(__file__))

    # 4. Execute Ray Serve
    print("\n[LAUNCH] Starting Ray Serve Application...")
    print(f"Ray Address: {RAY_ADDRESS}")
    print("API will be available at: http://localhost:8000/v1")
    print("---------------------------------------------------\n")

    # Command: serve run serve_glm:app
    cmd = ["serve", "run", "serve_glm:app"]
    
    try:
        subprocess.run(cmd, env=env, cwd=cwd, check=True)
    except KeyboardInterrupt:
        print("\n[STOP] Shutting down Serve...")
    except subprocess.CalledProcessError as e:
        print(f"[ERROR] Serve failed with code {e.returncode}")

if __name__ == "__main__":
    main()