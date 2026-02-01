   LLM inferencing on multiple servers and multiple GPUs with ray and vllm                   

Toggle navigation [pavlokhmel.com](https://pavlokhmel.com/)

*   [About](https://pavlokhmel.com/pages/about.html)

LLM inferencing on multiple servers and multiple GPUs with ray and vllm
=======================================================================

Posted on Tue 29 July 2025 by Pavlo Khmel

There are large language models (LLM) that cannot start on a single computer, even with multiple GPUs. They need more video memory to start.

For example, the full version of DeepSeek-R1 models with 671B parameters is estimated to utilize 16 GPUs with 80GB of video memory each.

### Video version of this article on YouTube

### Inference

The usage of a trained LLM is called "inference". I will use 4 servers with 16 A100 GPUs in total for inference.

There are several different versions of DeepSeek-R1 models: full (original), quantized, and distilled models.

Some of them can start on a single server with a single GPU and even on a smartphone.

### Full (original) vs quantized vs distilled Models

Distillation and quantization are both techniques used to optimize machine learning models:

*   Model distillation - creates a new, smaller model that learns from a larger model. In this case smaller models like Llama and Qwen were used to learn from a full DeepSeek model.
*   Model quantization - reduces model size by reducing the numerical precision of model parameters.

### vLLM and Ray cluster

It is possible to use software like ollama to run optimized models on a single computer on Linux, Mac, or Windows. On iPhone or Android applications like PocketPal AI can be used.

However, ollama cannot run models on several computers.

vLLM with Ray cluster can inference LLM on multiple servers.

### Setup

*   4 servers
*   16 \* A100 GPUs with 80GB VRAM
*   Rocky Linux 9.6
*   nvidia-driver-575.57.08-1.el9.x86\_64
*   cuda-toolkit-12-9
*   Python 3.9.21 (default python)
*   Shared filesystem mounted on all server: /cluster/

An additional package python3-devel was needed on all nodes:

`dnf -y install python3-devel`

### Ray and vLLM installation

Installation done from one server (server-01) to the shared filesystem /cluster so other servers can use it.

Create a Python virtual environment and activate:

`mkdir /cluster/llm python -m venv /cluster/llm/rayvllm source /cluster/llm/rayvllm/bin/activate`

Install Ray and vLLM:

`pip install "ray[serve]" pip install vllm --extra-index-url https://download.pytorch.org/whl/cu128`

These 4 servers have multiple IP addresses. I will use only these:

`server-01 - 10.3.6.1 server-02 - 10.3.6.2 server-03 - 10.3.6.3 server-04 - 10.3.6.4`

NOTE: In case of multiple IP addresses on the servers, it is important to set VLLM\_HOST\_IP before starting Ray to avoid error. Because vLLM or Ray will try to use the wrong IP address.

### Starting Ray cluster

Commands on server-01. It will be Ray head node:

`source /cluster/llm/rayvllm/bin/activate export VLLM_HOST_IP=10.3.6.1 ray start --head --node-ip-address=10.3.6.1 --port=6379`

Commands on server-02:

`source /cluster/llm/rayvllm/bin/activate export VLLM_HOST_IP=10.3.6.2 ray start --address=10.3.6.1:6379 --node-ip-address=10.3.6.2`

Commands on server-03:

`source /cluster/llm/rayvllm/bin/activate export VLLM_HOST_IP=10.3.6.3 ray start --address=10.3.6.1:6379 --node-ip-address=10.3.6.3`

Commands on server-04:

`source /cluster/llm/rayvllm/bin/activate export VLLM_HOST_IP=10.3.6.4 ray start --address=10.3.6.1:6379 --node-ip-address=10.3.6.4`

Check status from head node ( server-01 ) with commands:

`ray status ray list nodes`

Command "ray list nodes" can fail on the head node in case wrong IP addresses were used.

Expected output "ray status":

`# ray status ======== Autoscaler status: 2025-07-28 19:44:04.825150 ======== Node status --------------------------------------------------------------- Active:  1 node_36ab5d7fb569ea75527390ab373569def5edf8efe61324fe2e354b29  1 node_64fb807cc70316d28655879deef253a39832a4c3856d3da164e73043  1 node_50b5f3271e098d68f7561698c896350f4293ad89d85917d1aa36be85  1 node_a64e56cadd90931b1e3d490a528dc0a97ff97e894d87a0f3338f91b6 Pending:  (no pending nodes) Recent failures:  (no failures)  Resources --------------------------------------------------------------- Total Usage:  0.0/256.0 CPU  0.0/16.0 GPU  0B/3.19TiB memory  0B/745.06GiB object_store_memory  Total Constraints:  (no request_resources() constraints) Total Demands:  (no resource demands)`

### Download DeepSeek model

`cd /cluster/llm git clone https://huggingface.co/deepseek-ai/DeepSeek-R1`

Downloaded size 1.3T /cluster/llm/DeepSeek-R1/

Sub-directory /cluster/llm/DeepSeek-R1/.git with size 642G can be deleted.

### Starting vLLM from any server.

I will use head node ( server-01):

`vllm serve /cluster/llm/DeepSeek-R1 --tensor-parallel-size 16 --port 8000 --max-model-len 20480`

### Use model from command line:

`vllm chat --url http://10.3.6.1:8000/v1`

### Connect vLLM to web interface like Open WebUI

Admin Panel > Settings > Connections > Manage OpenAI API Connections > Add connection:

Using URL http://10.3.6.1:8000/v1 because I used the head node to start vLLM.

* * *

* * *

*   [](https://pavlokhmel.com/llm_inferencing_on_multiple_servers_and_multiple_gpus_with_ray_and_vllm.html#)
*   [](https://pavlokhmel.com/llm_inferencing_on_multiple_servers_and_multiple_gpus_with_ray_and_vllm.html#)
