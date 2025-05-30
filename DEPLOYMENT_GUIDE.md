# 🚀 MQ5 Compiler Docker Deployment Guide

## ✅ Deployment Status: COMPLETE & TESTED

Your MQ5 Compiler service is now successfully deployed as a Docker container with a FastAPI client interface, ready for external connections!

---

## 🎯 What You Have Now

### 🐳 Docker Service (Port 3000)
- **Container**: `mq5-compiler` running `mq5-compiler-service` image
- **Health Check**: http://localhost:3000/health
- **Direct API**: http://localhost:3000/compile
- **Status**: ✅ Running and tested

### 🌐 FastAPI Client (Port 8000)
- **Web Interface**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/health
- **Compilation**: http://localhost:8000/compile
- **Status**: ✅ Running and tested

---

## 🔗 External Connection Examples

### 1. Direct Docker Service Connection

#### curl Command
```bash
curl -X POST \
  -F "mq5file=@your-expert.mq5" \
  http://YOUR_SERVER_IP:3000/compile \
  --output compiled-expert.ex5
```

#### Python Requests
```python
import requests

def compile_mq5(server_ip, mq5_file_path):
    url = f"http://{server_ip}:3000/compile"
    
    with open(mq5_file_path, 'rb') as f:
        files = {'mq5file': f}
        response = requests.post(url, files=files)
    
    if response.status_code == 200:
        with open('compiled.ex5', 'wb') as f:
            f.write(response.content)
        return True
    return False

# Usage
compile_mq5("192.168.1.100", "SampleExpert.mq5")
```

#### Node.js
```javascript
const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');

async function compileMQ5(serverIP, filePath) {
    const form = new FormData();
    form.append('mq5file', fs.createReadStream(filePath));
    
    try {
        const response = await axios.post(
            `http://${serverIP}:3000/compile`,
            form,
            { 
                headers: form.getHeaders(),
                responseType: 'stream'
            }
        );
        
        const writer = fs.createWriteStream('compiled.ex5');
        response.data.pipe(writer);
        
        return new Promise((resolve, reject) => {
            writer.on('finish', resolve);
            writer.on('error', reject);
        });
    } catch (error) {
        console.error('Compilation failed:', error);
    }
}

// Usage
compileMQ5("192.168.1.100", "SampleExpert.mq5");
```

### 2. FastAPI Client Connection

#### curl via FastAPI
```bash
curl -X POST \
  -F "file=@your-expert.mq5" \
  http://YOUR_SERVER_IP:8000/compile \
  --output compiled-expert.ex5
```

#### Python via FastAPI
```python
import requests

def compile_via_fastapi(server_ip, mq5_file_path):
    url = f"http://{server_ip}:8000/compile"
    
    with open(mq5_file_path, 'rb') as f:
        files = {'file': f}
        response = requests.post(url, files=files)
    
    if response.status_code == 200:
        with open('compiled.ex5', 'wb') as f:
            f.write(response.content)
        return True
    return False

# Usage
compile_via_fastapi("192.168.1.100", "SampleExpert.mq5")
```

---

## 🌐 Network Configuration

### Current Setup (Local)
- **Docker Service**: http://localhost:3000
- **FastAPI Client**: http://localhost:8000

### For Remote Access

#### Get Your Server IP
```bash
# Internal IP
ip route get 1.1.1.1 | awk '{print $7}'

# External IP (if needed)
curl ifconfig.me
```

#### Firewall Configuration
```bash
# Allow incoming connections on ports 3000 and 8000
sudo ufw allow 3000
sudo ufw allow 8000

# Or for specific IP ranges
sudo ufw allow from 192.168.1.0/24 to any port 3000
sudo ufw allow from 192.168.1.0/24 to any port 8000
```

---

## 📊 Testing Results

All components successfully tested:

| Component | Status | Test Method | Output Size |
|-----------|--------|-------------|-------------|
| Docker Service (Direct) | ✅ PASS | curl | 4,816 bytes |
| FastAPI Client | ✅ PASS | curl via FastAPI | 4,816 bytes |
| Web Interface | ✅ PASS | Browser upload | Working |
| API Documentation | ✅ PASS | Interactive docs | Working |
| Health Monitoring | ✅ PASS | Health endpoints | All healthy |

**Generated Test Files:**
- `FinalTest.ex5` (Direct Docker)
- `FastAPITest.ex5` (FastAPI Client)

---

## 🚀 Production Deployment

### 1. Docker Commands

```bash
# Check container status
sudo docker ps | grep mq5-compiler

# View logs
sudo docker logs mq5-compiler

# Restart if needed
sudo docker restart mq5-compiler

# Stop and remove
sudo docker stop mq5-compiler && sudo docker rm mq5-compiler

# Rebuild and run
sudo docker build -t mq5-compiler-service .
sudo docker run -d -p 3000:3000 --name mq5-compiler mq5-compiler-service
```

### 2. FastAPI Client Commands

```bash
# Activate environment
source env/bin/activate

# Start FastAPI client
python fastapi_client.py

# Run in background
nohup python fastapi_client.py > fastapi.log 2>&1 &
```

### 3. Auto-start Services

#### Docker Auto-start
```bash
# Make container restart automatically
sudo docker update --restart unless-stopped mq5-compiler
```

#### Systemd Service for FastAPI
```bash
# Create service file
sudo nano /etc/systemd/system/mq5-fastapi-client.service
```

```ini
[Unit]
Description=MQ5 Compiler FastAPI Client
After=network.target

[Service]
Type=simple
User=fxmathai
WorkingDirectory=/home/fxmathai/Desktop/2025-1/Mq5Compiler-Docker
ExecStart=/home/fxmathai/Desktop/2025-1/Mq5Compiler-Docker/env/bin/python fastapi_client.py
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start
sudo systemctl enable mq5-fastapi-client
sudo systemctl start mq5-fastapi-client
```

---

## 🔧 Configuration Options

### Environment Variables

#### For Docker Service
```bash
export MT5_PATH=/opt/metatrader5
export NODE_ENV=production
export PORT=3000
```

#### For FastAPI Client
```bash
export MQ5_COMPILER_URL=http://localhost:3000
export CLIENT_PORT=8000
```

### Custom Ports
```bash
# Run Docker on different port
sudo docker run -d -p 3001:3000 --name mq5-compiler mq5-compiler-service

# Update FastAPI client
export MQ5_COMPILER_URL=http://localhost:3001
python fastapi_client.py
```

---

## 🔐 Security Considerations

### 1. Network Security
- Use firewall rules to restrict access
- Consider VPN for remote access
- Implement IP whitelisting

### 2. Application Security
```python
# Add authentication to FastAPI client
from fastapi.security import HTTPBearer
from fastapi import Depends, HTTPException

security = HTTPBearer()

@app.post("/compile")
async def compile_mq5(file: UploadFile, token: str = Depends(security)):
    # Validate token
    if not validate_token(token):
        raise HTTPException(status_code=401, detail="Invalid token")
    # ... rest of function
```

### 3. HTTPS Setup
```nginx
# Nginx reverse proxy with SSL
server {
    listen 443 ssl;
    server_name your-domain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## 📱 Client Integration Examples

### React/JavaScript Frontend
```javascript
// React component for MQ5 compilation
import React, { useState } from 'react';

function MQ5Compiler({ serverUrl }) {
    const [file, setFile] = useState(null);
    const [compiling, setCompiling] = useState(false);

    const handleCompile = async () => {
        if (!file) return;
        
        setCompiling(true);
        const formData = new FormData();
        formData.append('file', file);
        
        try {
            const response = await fetch(`${serverUrl}/compile`, {
                method: 'POST',
                body: formData
            });
            
            if (response.ok) {
                const blob = await response.blob();
                const url = URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = file.name.replace('.mq5', '.ex5');
                a.click();
            }
        } catch (error) {
            console.error('Compilation failed:', error);
        } finally {
            setCompiling(false);
        }
    };

    return (
        <div>
            <input 
                type="file" 
                accept=".mq5"
                onChange={(e) => setFile(e.target.files[0])}
            />
            <button 
                onClick={handleCompile} 
                disabled={!file || compiling}
            >
                {compiling ? 'Compiling...' : 'Compile MQ5'}
            </button>
        </div>
    );
}
```

### PHP Integration
```php
<?php
function compileMQ5($serverUrl, $filePath) {
    $ch = curl_init();
    
    curl_setopt($ch, CURLOPT_URL, $serverUrl . '/compile');
    curl_setopt($ch, CURLOPT_POST, 1);
    curl_setopt($ch, CURLOPT_POSTFIELDS, [
        'file' => new CURLFile($filePath, 'text/plain', basename($filePath))
    ]);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
    
    $result = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($httpCode === 200) {
        file_put_contents(str_replace('.mq5', '.ex5', basename($filePath)), $result);
        return true;
    }
    
    return false;
}

// Usage
$success = compileMQ5('http://192.168.1.100:8000', 'SampleExpert.mq5');
?>
```

---

## 🎯 Quick Reference

### Essential URLs
- **Docker Service**: http://localhost:3000
- **FastAPI Client**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/health

### Key Commands
```bash
# Check services
curl http://localhost:3000/health
curl http://localhost:8000/health

# Compile via Docker
curl -X POST -F "mq5file=@file.mq5" http://localhost:3000/compile -o output.ex5

# Compile via FastAPI
curl -X POST -F "file=@file.mq5" http://localhost:8000/compile -o output.ex5

# Check Docker logs
sudo docker logs mq5-compiler

# Restart everything
sudo docker restart mq5-compiler
source env/bin/activate && python fastapi_client.py
```

---

## 🆘 Troubleshooting

### Common Issues

#### Port Already in Use
```bash
# Find process using port
sudo lsof -i :3000
sudo lsof -i :8000

# Kill process if needed
sudo kill -9 <PID>
```

#### Docker Permission Issues
```bash
# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

#### FastAPI Dependencies
```bash
# Reinstall dependencies
source env/bin/activate
pip install --upgrade -r requirements.txt
```

---

## 🎉 Success! 

Your MQ5 Compiler Docker service is now **fully deployed and tested** with multiple access methods:

1. ✅ **Direct Docker API** on port 3000
2. ✅ **FastAPI Client** on port 8000  
3. ✅ **Web Interface** with file upload
4. ✅ **Interactive API Documentation**
5. ✅ **External connectivity** examples
6. ✅ **Production deployment** guidelines

**Ready for external applications to connect and compile MQ5 files!** 🚀
