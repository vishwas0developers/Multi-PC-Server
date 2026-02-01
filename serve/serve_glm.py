import os
from ray import serve
from ray.serve.llm import LLMConfig, build_openai_app

# 1. Get Dynamic Configuration
model_path = os.environ.get("TARGET_MODEL_PATH")
host_ip = os.environ.get("VLLM_HOST_IP", "0.0.0.0")

if not model_path:
    # Fallback for testing if env var not set
    model_path = "/mnt/d/Ai_Model/Huggingface/hub/models--zai-org--GLM-4.6/snapshots/be72194883d968d7923a07e2f61681ea9a2826d1"

print(f"[SERVE] Loading model from: {model_path}")

# 2. Define LLM Configuration
llm_config = LLMConfig(
    model_loading_config=dict(
        model_id="glm-4-6",
        model_source=model_path,
    ),
    deployment_config=dict(
        autoscaling_config=dict(
            min_replicas=1,
            max_replicas=1,
        )
    ),
    # FIX: 'GPU' allowed nahi hai. 'A10G' use karein validation pass karne ke liye.
    # Ye bas config validation ke liye hai, Ray physical GPU hi use karega.
    accelerator_type="A10G",
    
    engine_kwargs=dict(
        tensor_parallel_size=1,       # 1 GPU per Node
        pipeline_parallel_size=2,     # 2 Nodes Total
        max_model_len=32768,
        trust_remote_code=True,
        gpu_memory_utilization=0.90,
        swap_space=4,
    ),
)

# 3. Build Application
app = build_openai_app({"llm_configs": [llm_config]})