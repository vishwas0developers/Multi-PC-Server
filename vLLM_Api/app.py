import os
import httpx
import uvicorn
from fastapi import FastAPI, Request, HTTPException, BackgroundTasks
from fastapi.responses import JSONResponse, StreamingResponse
from contextlib import asynccontextmanager
from typing import Dict, Any, List

# Import config
from . import config
from . import health_check

@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Lifespan context manager for the Gateway.
    Checks if the external vLLM server is reachable at startup.
    """
    print("--- Starting vLLM Gateway ---")
    print(f"Target vLLM Server: {config.VLLM_BASE_URL}")
    
    # Simple startup check
    if health_check.check_health():
        print("✅ vLLM Server is reachable!")
    else:
        print("⚠️ vLLM Server not yet reachable. Gateway will retry connections on request.")
    
    yield
    
    print("Shutting down vLLM Gateway...")

app = FastAPI(title="vLLM Gateway API (Ray Cluster)", lifespan=lifespan)

# --- Proxy Helper ---

async def proxy_request(request: Request, path: str):
    """
    Proxies a request to the vLLM server.
    """
    url = f"{config.VLLM_BASE_URL}/{path}"
    
    # Verify health before forwarding?
    # User requested: "check Ray cluster status and only proxy if cluster is healthy"
    # To avoid latency on every request, we might want to skip this or do it asynchronously.
    # But strictly following instructions:
    if not health_check.check_health():
        raise HTTPException(status_code=503, detail="vLLM Cluster is currently unavailable")

    try:
        async with httpx.AsyncClient() as client:
            # Forward the request method, headers (auth), and body
            # We exclude 'host' header to avoid confusion at the destination
            headers = dict(request.headers)
            headers.pop("host", None)
            headers.pop("content-length", None) # Let httpx handle this
            
            # Streaming support for chat/completions
            req_body = await request.body()
            
            # Build request
            rp_req = client.build_request(
                request.method,
                url,
                headers=headers,
                content=req_body,
                timeout=300.0 # Long timeout for inference
            )
            
            rp_resp = await client.send(rp_req, stream=True)
            
            return StreamingResponse(
                rp_resp.aiter_raw(),
                status_code=rp_resp.status_code,
                headers=dict(rp_resp.headers),
                background=BackgroundTasks([rp_resp.aclose])
            )
            
    except httpx.RequestError as exc:
        raise HTTPException(status_code=502, detail=f"Error connecting to vLLM: {str(exc)}")

# --- Routes ---

@app.get("/")
def read_root():
    return {
        "status": "online",
        "service": "vLLM Gateway (Ray Cluster)",
        "target": config.VLLM_BASE_URL
    }

@app.get("/health")
def health():
    """Check health of the underlying vLLM server."""
    is_healthy = health_check.check_health()
    status = health_check.get_server_status()
    if not is_healthy:
        raise HTTPException(status_code=503, detail="vLLM Server is not ready")
    return status

# --- OpenAI Compatible Proxy Routes ---

@app.post("/v1/chat/completions")
async def chat_completions(request: Request):
    return await proxy_request(request, "chat/completions")

@app.post("/v1/completions")
async def completions(request: Request):
    return await proxy_request(request, "completions")

@app.post("/v1/embeddings")
async def embeddings(request: Request):
    return await proxy_request(request, "embeddings")

@app.get("/v1/models")
async def models(request: Request):
    return await proxy_request(request, "models")

if __name__ == "__main__":
    # Run the Gateway on Port 8000 (External)
    uvicorn.run(app, host="0.0.0.0", port=8000)
