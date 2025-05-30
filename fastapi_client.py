#!/usr/bin/env python3
"""
FastAPI Client for MQ5 Compiler Service
========================================

This FastAPI application demonstrates how to create a web interface
that connects to the MQ5 Compiler Docker service and provides a
user-friendly API for compiling MQ5 files.

Features:
- Upload MQ5 files via web interface
- Forward compilation requests to Docker service
- Return compiled EX5 files
- Health monitoring
- Error handling

Usage:
    python3 fastapi_client.py

    Then visit:
    - http://localhost:8000 - API documentation
    - http://localhost:8000/docs - Interactive API docs
    - http://localhost:8000/compile - Compilation endpoint
"""

import os
import sys
import aiofiles
import requests
from typing import Optional
from fastapi import FastAPI, File, UploadFile, HTTPException, Response
from fastapi.responses import FileResponse, HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import tempfile
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration
MQ5_COMPILER_URL = os.getenv("MQ5_COMPILER_URL", "http://localhost:3000")
CLIENT_PORT = int(os.getenv("CLIENT_PORT", "8000"))

# Create FastAPI app
app = FastAPI(
    title="MQ5 Compiler Client",
    description="FastAPI client for MQ5 Compiler Docker service",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/", response_class=HTMLResponse)
async def root():
    """Root endpoint with basic HTML interface"""
    html_content = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>MQ5 Compiler Client</title>
        <style>
            body {{ font-family: Arial, sans-serif; margin: 40px; }}
            .container {{ max-width: 600px; margin: 0 auto; }}
            .upload-form {{ border: 2px dashed #ccc; padding: 20px; margin: 20px 0; }}
            button {{ background: #007bff; color: white; padding: 10px 20px; border: none; cursor: pointer; }}
            button:hover {{ background: #0056b3; }}
            .result {{ margin-top: 20px; padding: 10px; background: #f8f9fa; border-radius: 4px; }}
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🚀 MQ5 Compiler Client</h1>
            <p>Upload your MQ5 files to compile them using the Docker service.</p>
            
            <div class="upload-form">
                <h3>📁 Upload MQ5 File</h3>
                <form action="/compile" method="post" enctype="multipart/form-data">
                    <input type="file" name="file" accept=".mq5" required>
                    <br><br>
                    <button type="submit">🔨 Compile</button>
                </form>
            </div>
            
            <div>
                <h3>📋 API Endpoints</h3>
                <ul>
                    <li><a href="/docs">📖 Interactive API Documentation</a></li>
                    <li><a href="/health">💚 Health Check</a></li>
                    <li><a href="/compiler-health">🐳 Docker Service Health</a></li>
                </ul>
            </div>
            
            <div>
                <h3>🔧 Configuration</h3>
                <p><strong>MQ5 Compiler Service:</strong> {compiler_url}</p>
                <p><strong>Client Port:</strong> {client_port}</p>
            </div>
        </div>
    </body>
    </html>
    """.format(compiler_url=MQ5_COMPILER_URL, client_port=CLIENT_PORT)
    
    return HTMLResponse(content=html_content)

@app.get("/health")
async def health_check():
    """Health check for this FastAPI client"""
    return {
        "status": "healthy",
        "service": "MQ5 Compiler FastAPI Client",
        "version": "1.0.0",
        "compiler_url": MQ5_COMPILER_URL
    }

@app.get("/compiler-health")
async def compiler_health_check():
    """Check health of the MQ5 Compiler Docker service"""
    try:
        response = requests.get(f"{MQ5_COMPILER_URL}/health", timeout=10)
        if response.status_code == 200:
            return {
                "docker_service": "healthy",
                "docker_response": response.json(),
                "client_status": "connected"
            }
        else:
            return {
                "docker_service": "unhealthy",
                "status_code": response.status_code,
                "client_status": "connection_error"
            }
    except requests.exceptions.RequestException as e:
        logger.error(f"Failed to connect to MQ5 Compiler service: {e}")
        raise HTTPException(
            status_code=503,
            detail=f"Cannot connect to MQ5 Compiler service at {MQ5_COMPILER_URL}"
        )

@app.post("/compile")
async def compile_mq5(file: UploadFile = File(...)):
    """
    Compile an MQ5 file using the Docker service
    
    Args:
        file: The MQ5 file to compile
        
    Returns:
        FileResponse: The compiled EX5 file
    """
    # Validate file
    if not file.filename.endswith('.mq5'):
        raise HTTPException(status_code=400, detail="File must have .mq5 extension")
    
    logger.info(f"Received file for compilation: {file.filename}")
    
    try:
        # Read file content
        file_content = await file.read()
        
        # Create temporary file
        with tempfile.NamedTemporaryFile(delete=False, suffix='.mq5') as temp_file:
            temp_file.write(file_content)
            temp_file_path = temp_file.name
        
        try:
            # Send to MQ5 Compiler service
            with open(temp_file_path, 'rb') as f:
                files = {'mq5file': (file.filename, f, 'text/plain')}
                response = requests.post(
                    f"{MQ5_COMPILER_URL}/compile",
                    files=files,
                    timeout=60
                )
            
            if response.status_code == 200:
                # Save compiled file
                output_filename = file.filename.replace('.mq5', '.ex5')
                output_path = f"/tmp/{output_filename}"
                
                with open(output_path, 'wb') as f:
                    f.write(response.content)
                
                logger.info(f"Compilation successful: {output_filename}")
                
                # Return compiled file
                return FileResponse(
                    path=output_path,
                    filename=output_filename,
                    media_type='application/octet-stream'
                )
            else:
                logger.error(f"Compilation failed with status {response.status_code}")
                raise HTTPException(
                    status_code=response.status_code,
                    detail=f"Compilation failed: {response.text}"
                )
                
        finally:
            # Clean up temporary file
            os.unlink(temp_file_path)
            
    except requests.exceptions.RequestException as e:
        logger.error(f"Request to MQ5 Compiler service failed: {e}")
        raise HTTPException(
            status_code=503,
            detail=f"Failed to connect to MQ5 Compiler service: {str(e)}"
        )
    except Exception as e:
        logger.error(f"Unexpected error during compilation: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Internal error: {str(e)}"
        )

@app.post("/compile-batch")
async def compile_batch(files: list[UploadFile] = File(...)):
    """
    Compile multiple MQ5 files
    
    Args:
        files: List of MQ5 files to compile
        
    Returns:
        JSON response with compilation results
    """
    results = []
    
    for file in files:
        try:
            # Validate file
            if not file.filename.endswith('.mq5'):
                results.append({
                    "filename": file.filename,
                    "status": "error",
                    "message": "File must have .mq5 extension"
                })
                continue
            
            # Read file content
            file_content = await file.read()
            
            # Create temporary file
            with tempfile.NamedTemporaryFile(delete=False, suffix='.mq5') as temp_file:
                temp_file.write(file_content)
                temp_file_path = temp_file.name
            
            try:
                # Send to MQ5 Compiler service
                with open(temp_file_path, 'rb') as f:
                    files_data = {'mq5file': (file.filename, f, 'text/plain')}
                    response = requests.post(
                        f"{MQ5_COMPILER_URL}/compile",
                        files=files_data,
                        timeout=60
                    )
                
                if response.status_code == 200:
                    results.append({
                        "filename": file.filename,
                        "status": "success",
                        "output_size": len(response.content),
                        "output_filename": file.filename.replace('.mq5', '.ex5')
                    })
                else:
                    results.append({
                        "filename": file.filename,
                        "status": "error",
                        "message": f"Compilation failed: {response.text}"
                    })
                    
            finally:
                # Clean up temporary file
                os.unlink(temp_file_path)
                
        except Exception as e:
            results.append({
                "filename": file.filename,
                "status": "error",
                "message": str(e)
            })
    
    return {"results": results}

if __name__ == "__main__":
    print(f"🚀 Starting MQ5 Compiler FastAPI Client on port {CLIENT_PORT}")
    print(f"🐳 Connecting to MQ5 Compiler service at: {MQ5_COMPILER_URL}")
    print(f"📖 API Documentation: http://localhost:{CLIENT_PORT}/docs")
    print(f"🌐 Web Interface: http://localhost:{CLIENT_PORT}")
    
    uvicorn.run(
        "fastapi_client:app",
        host="0.0.0.0",
        port=CLIENT_PORT,
        reload=False,
        log_level="info"
    )
