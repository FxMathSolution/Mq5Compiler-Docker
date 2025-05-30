#!/usr/bin/env node

const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const path = require('path');

/**
 * MQ5 Compiler Client
 * Example client for sending MQ5 files to the compiler service
 */

class MQ5CompilerClient {
  constructor(baseUrl = 'http://localhost:3000') {
    this.baseUrl = baseUrl;
  }

  /**
   * Compile a single MQ5 file
   * @param {string} filePath - Path to the MQ5 file
   * @param {string} outputPath - Path where to save the compiled EX5 file
   * @returns {Promise<Object>} Compilation result
   */
  async compileFile(filePath, outputPath = null) {
    try {
      console.log(`Compiling file: ${filePath}`);
      
      // Check if file exists
      if (!fs.existsSync(filePath)) {
        throw new Error(`File not found: ${filePath}`);
      }

      // Create form data
      const form = new FormData();
      form.append('mq5file', fs.createReadStream(filePath));

      // Send request
      const response = await axios.post(`${this.baseUrl}/compile`, form, {
        headers: {
          ...form.getHeaders(),
        },
        responseType: 'arraybuffer', // For binary file download
        timeout: 60000 // 60 seconds timeout
      });

      // Save the compiled file
      if (!outputPath) {
        const baseName = path.basename(filePath, path.extname(filePath));
        outputPath = `${baseName}.ex5`;
      }

      fs.writeFileSync(outputPath, response.data);
      
      console.log(`✅ Compilation successful!`);
      console.log(`📁 Output file: ${outputPath}`);
      console.log(`📊 File size: ${this.formatFileSize(response.data.length)}`);

      return {
        success: true,
        outputPath: outputPath,
        size: response.data.length
      };

    } catch (error) {
      console.error(`❌ Compilation failed:`, error.message);
      
      if (error.response) {
        console.error(`Status: ${error.response.status}`);
        if (error.response.data) {
          try {
            const errorData = JSON.parse(error.response.data.toString());
            console.error(`Error details:`, errorData);
            return {
              success: false,
              error: errorData.error,
              details: errorData.details,
              logs: errorData.logs
            };
          } catch {
            console.error(`Raw error:`, error.response.data.toString());
          }
        }
      }
      
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Compile multiple MQ5 files
   * @param {string[]} filePaths - Array of file paths
   * @returns {Promise<Object>} Batch compilation result
   */
  async compileFiles(filePaths) {
    try {
      console.log(`Compiling ${filePaths.length} files...`);
      
      // Create form data
      const form = new FormData();
      
      for (const filePath of filePaths) {
        if (!fs.existsSync(filePath)) {
          console.warn(`⚠️  File not found: ${filePath}`);
          continue;
        }
        form.append('mq5files', fs.createReadStream(filePath));
      }

      // Send request
      const response = await axios.post(`${this.baseUrl}/compile-batch`, form, {
        headers: {
          ...form.getHeaders(),
        },
        timeout: 120000 // 2 minutes timeout for batch
      });

      console.log(`✅ Batch compilation completed!`);
      console.log(`📊 Results:`, response.data);

      return response.data;

    } catch (error) {
      console.error(`❌ Batch compilation failed:`, error.message);
      
      if (error.response && error.response.data) {
        console.error(`Error details:`, error.response.data);
      }
      
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Check service health
   * @returns {Promise<Object>} Health status
   */
  async checkHealth() {
    try {
      const response = await axios.get(`${this.baseUrl}/health`, {
        timeout: 5000
      });
      
      console.log(`✅ Service is healthy:`, response.data);
      return response.data;
      
    } catch (error) {
      console.error(`❌ Service health check failed:`, error.message);
      return {
        status: 'ERROR',
        error: error.message
      };
    }
  }

  /**
   * Format file size
   * @param {number} bytes - File size in bytes
   * @returns {string} Formatted file size
   */
  formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';
    
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }
}

// CLI usage
if (require.main === module) {
  const args = process.argv.slice(2);
  
  if (args.length === 0) {
    console.log(`
🔧 MQ5 Compiler Client

Usage:
  node client.js <command> [options]

Commands:
  health                     - Check service health
  compile <file>             - Compile a single MQ5 file
  compile <file> <output>    - Compile with custom output name
  batch <file1> <file2> ...  - Compile multiple files

Examples:
  node client.js health
  node client.js compile my-expert.mq5
  node client.js compile my-expert.mq5 compiled-expert.ex5
  node client.js batch expert1.mq5 expert2.mq5 indicator.mq5
    `);
    process.exit(1);
  }

  const client = new MQ5CompilerClient();
  const command = args[0];

  (async () => {
    switch (command) {
      case 'health':
        await client.checkHealth();
        break;
        
      case 'compile':
        if (args.length < 2) {
          console.error('❌ Please provide a file path');
          process.exit(1);
        }
        const result = await client.compileFile(args[1], args[2]);
        process.exit(result.success ? 0 : 1);
        break;
        
      case 'batch':
        if (args.length < 2) {
          console.error('❌ Please provide at least one file path');
          process.exit(1);
        }
        const batchResult = await client.compileFiles(args.slice(1));
        process.exit(batchResult.success !== false ? 0 : 1);
        break;
        
      default:
        console.error(`❌ Unknown command: ${command}`);
        process.exit(1);
    }
  })();
}

module.exports = MQ5CompilerClient;
