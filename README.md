# MQ5 Compiler Docker Service

A dockerized service for compiling MQ5 files to EX5 format. This service accepts MQ5 files via HTTP API, compiles them using MetaTrader 5 compiler, and returns the compiled EX5 files.

## Features

- 🔧 HTTP API for file compilation
- 📁 Single file and batch compilation support
- 🐳 Fully dockerized with Ubuntu base
- 🍷 Wine integration for running MetaTrader on Linux
- 🛡️ Security features (rate limiting, file validation, CORS)
- 📊 Health checks and monitoring
- 🧹 Automatic cleanup of temporary files

## Quick Start

### Using Docker Compose (Recommended)

1. **Clone and build the service:**
```bash
git clone <your-repo>
cd Mq5Compiler-Docker
docker-compose up --build
```

2. **Test the service:**
```bash
curl http://localhost:3000/health
```

### Manual Docker Build

```bash
# Build the image
docker build -t mq5-compiler .

# Run the container
docker run -d -p 3000:3000 --name mq5-compiler-service mq5-compiler
```

## API Endpoints

### Health Check
```bash
GET /health
```

### Compile Single File
```bash
POST /compile
Content-Type: multipart/form-data
```

**Parameters:**
- `mq5file` (file): The MQ5 file to compile

**Example using curl:**
```bash
curl -X POST \
  -F "mq5file=@your-expert.mq5" \
  http://localhost:3000/compile \
  --output compiled-expert.ex5
```

### Batch Compilation
```bash
POST /compile-batch
Content-Type: multipart/form-data
```

**Parameters:**
- `mq5files` (files): Multiple MQ5 files to compile

**Example using curl:**
```bash
curl -X POST \
  -F "mq5files=@expert1.mq5" \
  -F "mq5files=@expert2.mq5" \
  -F "mq5files=@indicator.mq5" \
  http://localhost:3000/compile-batch
```

## Client Examples

### Node.js Client

Install dependencies first:
```bash
npm install axios form-data
```

Then use the provided client:

```javascript
const MQ5CompilerClient = require('./client.js');

const client = new MQ5CompilerClient('http://localhost:3000');

// Compile a single file
await client.compileFile('my-expert.mq5', 'output.ex5');

// Batch compilation
await client.compileFiles(['expert1.mq5', 'expert2.mq5']);

// Health check
await client.checkHealth();
```

### CLI Usage

```bash
# Check service health
node client.js health

# Compile single file
node client.js compile my-expert.mq5

# Compile with custom output name
node client.js compile my-expert.mq5 compiled-expert.ex5

# Batch compilation
node client.js batch expert1.mq5 expert2.mq5 indicator.mq5
```

### Python Client Example

```python
import requests

def compile_mq5_file(file_path, server_url='http://localhost:3000'):
    """Compile MQ5 file using the Docker service"""
    
    url = f"{server_url}/compile"
    
    with open(file_path, 'rb') as file:
        files = {'mq5file': file}
        response = requests.post(url, files=files)
    
    if response.status_code == 200:
        # Save the compiled file
        output_path = file_path.replace('.mq5', '.ex5')
        with open(output_path, 'wb') as output_file:
            output_file.write(response.content)
        print(f"✅ Compilation successful: {output_path}")
        return True
    else:
        print(f"❌ Compilation failed: {response.text}")
        return False

# Usage
compile_mq5_file('my-expert.mq5')
```

### PHP Client Example

```php
<?php
function compileMQ5File($filePath, $serverUrl = 'http://localhost:3000') {
    $url = $serverUrl . '/compile';
    
    $cfile = new CURLFile($filePath);
    $data = array('mq5file' => $cfile);
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, 1);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    
    $result = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($httpCode === 200) {
        $outputPath = str_replace('.mq5', '.ex5', $filePath);
        file_put_contents($outputPath, $result);
        echo "✅ Compilation successful: $outputPath\n";
        return true;
    } else {
        echo "❌ Compilation failed: $result\n";
        return false;
    }
}

// Usage
compileMQ5File('my-expert.mq5');
?>
```

## Configuration

### Environment Variables

- `PORT` - Server port (default: 3000)
- `MT5_PATH` - Path to MetaTrader 5 installation (default: /opt/metatrader5)
- `NODE_ENV` - Environment (development/production)

### Docker Volumes

- `./uploads:/app/uploads` - Temporary upload directory
- `./compiled:/app/compiled` - Compiled files directory
- `./logs:/app/logs` - Log files directory

## Installation Requirements

For production use, you'll need:

1. **MetaTrader 5 Terminal** installed in the container
2. **Wine** configured properly for Linux environment
3. **Valid MetaTrader 5 license** for compilation

### Installing MetaTrader 5

Replace the mock installation in the Dockerfile with actual MT5 installation:

```dockerfile
# Download MetaTrader 5
RUN wget https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe
RUN wine mt5setup.exe /S

# Set correct path
ENV MT5_PATH=/root/.wine/drive_c/Program Files/MetaTrader 5
```

## Security Features

- Rate limiting (100 requests per 15 minutes per IP)
- File type validation
- File size limits (10MB max)
- CORS protection
- Helmet security headers
- Automatic cleanup of temporary files

## Monitoring

### Health Checks

The service includes built-in health checks:
- Docker health check every 30 seconds
- HTTP endpoint at `/health`
- Automatic container restart on failure

### Logging

Logs are available in the container and can be accessed via:
```bash
docker logs mq5-compiler-service
```

## Troubleshooting

### Common Issues

1. **Compilation fails**: Check if MetaTrader 5 is properly installed
2. **Wine errors**: Ensure Wine is configured correctly
3. **Permission issues**: Check file permissions in mounted volumes
4. **Memory issues**: Increase container memory limits

### Debug Mode

Run with debug logging:
```bash
docker run -e NODE_ENV=development -p 3000:3000 mq5-compiler
```

## Development

### Local Development

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Run with nodemon for auto-restart
npx nodemon src/server.js
```

### Testing

```bash
# Test with sample MQ5 file
curl -X POST \
  -F "mq5file=@test-files/sample.mq5" \
  http://localhost:3000/compile \
  --output test-output.ex5
```

## License

MIT License - See LICENSE file for details.

## Support

For issues and questions:
- Create an issue in the repository
- Check the logs: `docker logs mq5-compiler-service`
- Verify MetaTrader 5 installation and Wine configuration
