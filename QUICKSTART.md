# Quick Start Guide - MQ5 Compiler Docker Service

## 🚀 Quick Installation & Testing

### 1. Build and Start the Service

```bash
# Navigate to the project directory
cd /home/fxmathai/Desktop/2025-1/Mq5Compiler-Docker

# Build and start the service
./setup.sh build
./setup.sh run
```

### 2. Test the Service

```bash
# Check if service is running
./setup.sh test

# Or manually test health
curl http://localhost:3000/health
```

### 3. Compile Your First MQ5 File

**Using the provided sample:**
```bash
# Node.js client
node client.js compile test-files/SampleExpert.mq5

# Python client
python client.py compile test-files/SampleExpert.mq5

# PHP client
php client.php compile test-files/SampleExpert.mq5

# Bash client
./client.sh compile test-files/SampleExpert.mq5

# Direct curl
curl -X POST -F "mq5file=@test-files/SampleExpert.mq5" http://localhost:3000/compile --output SampleExpert.ex5
```

## 📁 Project Structure

```
Mq5Compiler-Docker/
├── 🐳 Docker Configuration
│   ├── Dockerfile              # Main Docker image
│   ├── docker-compose.yml      # Docker Compose setup
│   ├── start.sh               # Container startup script
│   └── mock-compiler.sh       # Mock compiler for testing
│
├── 🛠️ Service Code
│   ├── package.json           # Node.js dependencies
│   ├── src/
│   │   ├── server.js          # Main HTTP server
│   │   ├── compiler.js        # Compilation logic
│   │   └── utils/
│   │       └── fileHandler.js # File utilities
│   │
├── 🔧 Client Examples
│   ├── client.js              # Node.js client
│   ├── client.py              # Python client
│   ├── client.php             # PHP client
│   ├── client.sh              # Bash client
│   ├── client-package.json    # Client dependencies
│   └── requirements.txt       # Python dependencies
│
├── 📋 Setup & Documentation
│   ├── setup.sh               # Installation script
│   ├── README.md              # Full documentation
│   ├── QUICKSTART.md          # This guide
│   └── .gitignore
│
├── 📁 Test Files
│   └── test-files/
│       └── SampleExpert.mq5   # Sample MQ5 file
│
└── 📁 Runtime Directories
    ├── uploads/               # Temporary uploads
    ├── compiled/              # Compiled outputs
    ├── temp/                  # Temporary files
    └── logs/                  # Log files
```

## 🔧 Available Commands

### Setup Script Commands
```bash
./setup.sh build      # Build Docker image
./setup.sh run        # Start the service
./setup.sh stop       # Stop the service
./setup.sh restart    # Restart the service
./setup.sh logs       # View logs
./setup.sh test       # Run test compilation
./setup.sh clean      # Clean up containers
./setup.sh install    # Install client dependencies
```

### Client Commands

**Node.js Client:**
```bash
node client.js health                           # Health check
node client.js compile file.mq5                 # Compile single file
node client.js compile file.mq5 output.ex5      # Compile with custom output
node client.js batch file1.mq5 file2.mq5        # Batch compile
```

**Python Client:**
```bash
python client.py health                         # Health check
python client.py compile file.mq5               # Compile single file
python client.py batch file1.mq5 file2.mq5      # Batch compile
```

**PHP Client:**
```bash
php client.php health                           # Health check
php client.php compile file.mq5                 # Compile single file
```

**Bash Client:**
```bash
./client.sh health                              # Health check
./client.sh compile file.mq5                    # Compile single file
```

## 🌐 API Endpoints

### Health Check
```bash
GET http://localhost:3000/health
```

### Single File Compilation
```bash
POST http://localhost:3000/compile
Content-Type: multipart/form-data
Field: mq5file (file)
```

### Batch Compilation
```bash
POST http://localhost:3000/compile-batch
Content-Type: multipart/form-data
Field: mq5files (multiple files)
```

## 📤 Example Usage from Different Servers

### From Another Linux Server

**Using curl:**
```bash
# Upload and compile
curl -X POST \
  -F "mq5file=@/path/to/your/expert.mq5" \
  http://YOUR_DOCKER_SERVER:3000/compile \
  --output compiled-expert.ex5
```

**Using wget:**
```bash
# First, create a temporary script for multipart upload
cat > upload.sh << 'EOF'
#!/bin/bash
curl -X POST \
  -F "mq5file=@$1" \
  http://YOUR_DOCKER_SERVER:3000/compile \
  --output "${1%.mq*}.ex5"
EOF
chmod +x upload.sh

# Use it
./upload.sh my-expert.mq5
```

### From Windows Server

**Using PowerShell:**
```powershell
# PowerShell script to upload and compile
$uri = "http://YOUR_DOCKER_SERVER:3000/compile"
$filePath = "C:\path\to\your\expert.mq5"
$outputPath = "C:\path\to\output\expert.ex5"

$form = @{
    mq5file = Get-Item -Path $filePath
}

Invoke-RestMethod -Uri $uri -Method Post -Form $form -OutFile $outputPath
Write-Host "Compilation completed: $outputPath"
```

**Using .NET/C#:**
```csharp
using System;
using System.IO;
using System.Net.Http;
using System.Threading.Tasks;

class Program
{
    private static readonly HttpClient client = new HttpClient();
    
    static async Task Main(string[] args)
    {
        string serverUrl = "http://YOUR_DOCKER_SERVER:3000/compile";
        string inputFile = @"C:\path\to\expert.mq5";
        string outputFile = @"C:\path\to\expert.ex5";
        
        await CompileMQ5File(serverUrl, inputFile, outputFile);
    }
    
    static async Task CompileMQ5File(string url, string inputPath, string outputPath)
    {
        using var form = new MultipartFormDataContent();
        using var fileContent = new ByteArrayContent(await File.ReadAllBytesAsync(inputPath));
        
        form.Add(fileContent, "mq5file", Path.GetFileName(inputPath));
        
        var response = await client.PostAsync(url, form);
        
        if (response.IsSuccessStatusCode)
        {
            var compiledData = await response.Content.ReadAsByteArrayAsync();
            await File.WriteAllBytesAsync(outputPath, compiledData);
            Console.WriteLine($"✅ Compilation successful: {outputPath}");
        }
        else
        {
            Console.WriteLine($"❌ Compilation failed: {response.StatusCode}");
        }
    }
}
```

## 🔧 Production Setup

### For Real MetaTrader 5 Compilation

1. **Install MetaTrader 5 in the container:**
   
   Edit the `Dockerfile` and uncomment these lines:
   ```dockerfile
   RUN wget -O mt5setup.exe "https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe"
   RUN wine mt5setup.exe /S
   ENV MT5_PATH="/root/.wine/drive_c/Program Files/MetaTrader 5"
   ```

2. **Configure Wine properly:**
   ```bash
   # In the container
   winecfg  # Configure Wine settings
   winetricks  # Install additional Windows components if needed
   ```

3. **Set up persistent volumes:**
   ```yaml
   # In docker-compose.yml
   volumes:
     - ./uploads:/app/uploads
     - ./compiled:/app/compiled
     - ./logs:/app/logs
     - mt5_data:/root/.wine  # Persist Wine configuration
   ```

### Security Considerations

1. **Use HTTPS in production:**
   ```bash
   # Add SSL certificate to the container
   # Configure nginx reverse proxy with SSL
   ```

2. **Set up authentication:**
   ```javascript
   // Add to server.js
   app.use('/compile', authenticateUser);
   ```

3. **Configure firewall:**
   ```bash
   # Only allow specific IPs
   iptables -A INPUT -p tcp --dport 3000 -s YOUR_CLIENT_IP -j ACCEPT
   iptables -A INPUT -p tcp --dport 3000 -j DROP
   ```

## 🐛 Troubleshooting

### Common Issues

1. **Service won't start:**
   ```bash
   ./setup.sh logs  # Check logs
   docker-compose ps  # Check container status
   ```

2. **Compilation fails:**
   ```bash
   # Check if MetaTrader is properly installed
   docker exec -it mq5-compiler-service ls -la /opt/metatrader5/
   
   # Test the mock compiler directly
   docker exec -it mq5-compiler-service /opt/metatrader5/metaeditor64.exe
   ```

3. **File upload issues:**
   ```bash
   # Check file permissions
   ls -la uploads/ compiled/
   
   # Check disk space
   df -h
   ```

### Debug Mode

```bash
# Run in debug mode
docker-compose down
docker-compose up  # Run in foreground to see logs
```

## 📞 Support

- Check logs: `./setup.sh logs`
- Test service: `./setup.sh test`
- Restart service: `./setup.sh restart`
- Clean and rebuild: `./setup.sh clean && ./setup.sh build && ./setup.sh run`

---

**🎉 You're all set! Your MQ5 compiler service is ready to receive and compile MQ5 files from any server.**
