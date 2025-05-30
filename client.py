# Python client example for MQ5 Compiler Service

import requests
import os
import sys
from pathlib import Path

class MQ5CompilerClient:
    def __init__(self, base_url='http://localhost:3000'):
        self.base_url = base_url
    
    def compile_file(self, file_path, output_path=None):
        """Compile a single MQ5 file"""
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"File not found: {file_path}")
        
        url = f"{self.base_url}/compile"
        
        with open(file_path, 'rb') as file:
            files = {'mq5file': file}
            
            try:
                response = requests.post(url, files=files, timeout=60)
                
                if response.status_code == 200:
                    # Save the compiled file
                    if not output_path:
                        output_path = str(Path(file_path).with_suffix('.ex5'))
                    
                    with open(output_path, 'wb') as output_file:
                        output_file.write(response.content)
                    
                    print(f"✅ Compilation successful: {output_path}")
                    print(f"📊 File size: {self.format_file_size(len(response.content))}")
                    return True
                else:
                    error_data = response.json() if response.headers.get('content-type') == 'application/json' else {'error': response.text}
                    print(f"❌ Compilation failed: {error_data.get('error', 'Unknown error')}")
                    if 'details' in error_data:
                        print(f"Details: {error_data['details']}")
                    return False
                    
            except requests.exceptions.RequestException as e:
                print(f"❌ Request failed: {e}")
                return False
    
    def compile_files(self, file_paths):
        """Compile multiple MQ5 files"""
        url = f"{self.base_url}/compile-batch"
        
        files = []
        for file_path in file_paths:
            if os.path.exists(file_path):
                files.append(('mq5files', open(file_path, 'rb')))
            else:
                print(f"⚠️  File not found: {file_path}")
        
        if not files:
            print("❌ No valid files to compile")
            return False
        
        try:
            response = requests.post(url, files=files, timeout=120)
            
            # Close file handles
            for _, file_handle in files:
                file_handle.close()
            
            if response.status_code == 200:
                result = response.json()
                print(f"✅ Batch compilation completed!")
                print(f"📊 Results: {result['successfulCompilations']}/{result['totalFiles']} successful")
                
                for file_result in result['results']:
                    status = "✅" if file_result['success'] else "❌"
                    print(f"{status} {file_result['filename']}")
                    if not file_result['success']:
                        print(f"   Error: {file_result.get('error', 'Unknown error')}")
                
                return result['successfulCompilations'] > 0
            else:
                error_data = response.json() if response.headers.get('content-type') == 'application/json' else {'error': response.text}
                print(f"❌ Batch compilation failed: {error_data.get('error', 'Unknown error')}")
                return False
                
        except requests.exceptions.RequestException as e:
            print(f"❌ Request failed: {e}")
            return False
    
    def check_health(self):
        """Check service health"""
        url = f"{self.base_url}/health"
        
        try:
            response = requests.get(url, timeout=5)
            
            if response.status_code == 200:
                data = response.json()
                print(f"✅ Service is healthy: {data['status']}")
                print(f"🕐 Timestamp: {data['timestamp']}")
                return True
            else:
                print(f"❌ Service health check failed: {response.status_code}")
                return False
                
        except requests.exceptions.RequestException as e:
            print(f"❌ Health check failed: {e}")
            return False
    
    def format_file_size(self, bytes_size):
        """Format file size in human readable format"""
        if bytes_size == 0:
            return "0 Bytes"
        
        sizes = ["Bytes", "KB", "MB", "GB"]
        i = 0
        while bytes_size >= 1024 and i < len(sizes) - 1:
            bytes_size /= 1024
            i += 1
        
        return f"{bytes_size:.2f} {sizes[i]}"

# CLI usage
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("""
🔧 MQ5 Compiler Python Client

Usage:
  python client.py <command> [options]

Commands:
  health                     - Check service health
  compile <file>             - Compile a single MQ5 file
  compile <file> <output>    - Compile with custom output name
  batch <file1> <file2> ...  - Compile multiple files

Examples:
  python client.py health
  python client.py compile my-expert.mq5
  python client.py compile my-expert.mq5 compiled-expert.ex5
  python client.py batch expert1.mq5 expert2.mq5 indicator.mq5
        """)
        sys.exit(1)
    
    client = MQ5CompilerClient()
    command = sys.argv[1]
    
    if command == 'health':
        success = client.check_health()
        sys.exit(0 if success else 1)
        
    elif command == 'compile':
        if len(sys.argv) < 3:
            print("❌ Please provide a file path")
            sys.exit(1)
        
        output_path = sys.argv[3] if len(sys.argv) > 3 else None
        success = client.compile_file(sys.argv[2], output_path)
        sys.exit(0 if success else 1)
        
    elif command == 'batch':
        if len(sys.argv) < 3:
            print("❌ Please provide at least one file path")
            sys.exit(1)
        
        success = client.compile_files(sys.argv[2:])
        sys.exit(0 if success else 1)
        
    else:
        print(f"❌ Unknown command: {command}")
        sys.exit(1)
