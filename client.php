<?php
/**
 * PHP Client Example for MQ5 Compiler Service
 */

class MQ5CompilerClient {
    private $baseUrl;
    
    public function __construct($baseUrl = 'http://localhost:3000') {
        $this->baseUrl = $baseUrl;
    }
    
    /**
     * Compile a single MQ5 file
     */
    public function compileFile($filePath, $outputPath = null) {
        if (!file_exists($filePath)) {
            throw new Exception("File not found: $filePath");
        }
        
        $url = $this->baseUrl . '/compile';
        
        $cfile = new CURLFile($filePath);
        $data = array('mq5file' => $cfile);
        
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_POST, 1);
        curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 60);
        
        $result = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        if ($httpCode === 200) {
            if (!$outputPath) {
                $outputPath = str_replace('.mq5', '.ex5', $filePath);
            }
            
            file_put_contents($outputPath, $result);
            echo "✅ Compilation successful: $outputPath\n";
            echo "📊 File size: " . $this->formatFileSize(strlen($result)) . "\n";
            return true;
        } else {
            $errorData = json_decode($result, true);
            echo "❌ Compilation failed: " . ($errorData['error'] ?? 'Unknown error') . "\n";
            if (isset($errorData['details'])) {
                echo "Details: " . $errorData['details'] . "\n";
            }
            return false;
        }
    }
    
    /**
     * Check service health
     */
    public function checkHealth() {
        $url = $this->baseUrl . '/health';
        
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 5);
        
        $result = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        if ($httpCode === 200) {
            $data = json_decode($result, true);
            echo "✅ Service is healthy: " . $data['status'] . "\n";
            echo "🕐 Timestamp: " . $data['timestamp'] . "\n";
            return true;
        } else {
            echo "❌ Service health check failed: HTTP $httpCode\n";
            return false;
        }
    }
    
    private function formatFileSize($bytes) {
        if ($bytes == 0) return '0 Bytes';
        
        $k = 1024;
        $sizes = array('Bytes', 'KB', 'MB', 'GB');
        $i = floor(log($bytes) / log($k));
        
        return round($bytes / pow($k, $i), 2) . ' ' . $sizes[$i];
    }
}

// CLI usage
if (php_sapi_name() === 'cli') {
    if ($argc < 2) {
        echo "🔧 MQ5 Compiler PHP Client\n\n";
        echo "Usage:\n";
        echo "  php client.php <command> [options]\n\n";
        echo "Commands:\n";
        echo "  health                - Check service health\n";
        echo "  compile <file>        - Compile a single MQ5 file\n";
        echo "  compile <file> <out>  - Compile with custom output name\n\n";
        echo "Examples:\n";
        echo "  php client.php health\n";
        echo "  php client.php compile my-expert.mq5\n";
        echo "  php client.php compile my-expert.mq5 compiled.ex5\n";
        exit(1);
    }
    
    $client = new MQ5CompilerClient();
    $command = $argv[1];
    
    try {
        switch ($command) {
            case 'health':
                $success = $client->checkHealth();
                exit($success ? 0 : 1);
                
            case 'compile':
                if ($argc < 3) {
                    echo "❌ Please provide a file path\n";
                    exit(1);
                }
                
                $outputPath = $argc > 3 ? $argv[3] : null;
                $success = $client->compileFile($argv[2], $outputPath);
                exit($success ? 0 : 1);
                
            default:
                echo "❌ Unknown command: $command\n";
                exit(1);
        }
    } catch (Exception $e) {
        echo "❌ Error: " . $e->getMessage() . "\n";
        exit(1);
    }
}
?>
