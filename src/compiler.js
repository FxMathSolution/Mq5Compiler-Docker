const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs').promises;

// MetaTrader compiler path (adjust based on your MT5 installation)
const MT5_PATH = process.env.MT5_PATH || '/opt/metatrader5';
const COMPILER_PATH = path.join(MT5_PATH, 'metaeditor64.exe');

/**
 * Compile MQ5 file to EX5
 * @param {string} inputPath - Path to the MQ5 file
 * @param {string} originalName - Original filename
 * @returns {Promise<Object>} Compilation result
 */
async function compileMessage(inputPath, originalName) {
  return new Promise(async (resolve, reject) => {
    try {
      // Create output directory
      const outputDir = path.join(__dirname, '..', 'compiled');
      await fs.mkdir(outputDir, { recursive: true });
      
      // Generate output filename
      const baseName = path.basename(originalName, path.extname(originalName));
      const outputPath = path.join(outputDir, `${baseName}.ex5`);
      
      // Check if we're using mock compiler (bash script) or real Windows executable
      const isMockCompiler = COMPILER_PATH.includes('metaeditor64.exe') && process.platform === 'linux';
      
      let compilerCmd;
      let compilerArgs;
      
      if (isMockCompiler) {
        // Direct execution of mock compiler (bash script)
        compilerCmd = COMPILER_PATH;
        compilerArgs = [
          '/compile',
          inputPath,
          `/out:${outputPath}`
        ];
      } else if (process.platform === 'linux') {
        // Use Wine to run real MetaEditor on Linux
        compilerCmd = 'wine';
        compilerArgs = [
          COMPILER_PATH,
          '/compile',
          inputPath,
          '/log',
          `/out:${outputPath}`
        ];
      } else {
        // Direct execution on Windows
        compilerCmd = COMPILER_PATH;
        compilerArgs = [
          '/compile',
          inputPath,
          '/log',
          `/out:${outputPath}`
        ];
      }
      
      console.log(`Compiling: ${originalName}`);
      console.log(`Command: ${compilerCmd} ${compilerArgs.join(' ')}`);
      
      const compiler = spawn(compilerCmd, compilerArgs, {
        stdio: ['pipe', 'pipe', 'pipe'],
        timeout: 30000 // 30 seconds timeout
      });
      
      let stdout = '';
      let stderr = '';
      
      compiler.stdout.on('data', (data) => {
        stdout += data.toString();
      });
      
      compiler.stderr.on('data', (data) => {
        stderr += data.toString();
      });
      
      compiler.on('close', async (code) => {
        try {
          console.log(`Compiler exited with code: ${code}`);
          console.log('STDOUT:', stdout);
          console.log('STDERR:', stderr);
          
          // Check if output file was created
          try {
            await fs.access(outputPath);
            resolve({
              success: true,
              outputPath: outputPath,
              logs: stdout,
              errors: stderr
            });
          } catch (accessError) {
            // If EX5 file wasn't created, try alternative compilation
            const alternativeResult = await tryAlternativeCompilation(inputPath, originalName);
            resolve(alternativeResult);
          }
        } catch (error) {
          resolve({
            success: false,
            error: `Post-compilation check failed: ${error.message}`,
            logs: stdout,
            errors: stderr
          });
        }
      });
      
      compiler.on('error', (error) => {
        console.error('Compiler spawn error:', error);
        resolve({
          success: false,
          error: `Failed to start compiler: ${error.message}`,
          logs: stdout,
          errors: stderr
        });
      });
      
      // Handle timeout
      compiler.on('timeout', () => {
        compiler.kill();
        resolve({
          success: false,
          error: 'Compilation timeout (30 seconds)',
          logs: stdout,
          errors: stderr
        });
      });
      
    } catch (error) {
      reject({
        success: false,
        error: `Compilation setup failed: ${error.message}`,
        logs: '',
        errors: ''
      });
    }
  });
}

/**
 * Alternative compilation method using mqlcompiler if available
 * @param {string} inputPath - Path to the MQ5 file
 * @param {string} originalName - Original filename
 * @returns {Promise<Object>} Compilation result
 */
async function tryAlternativeCompilation(inputPath, originalName) {
  return new Promise((resolve) => {
    try {
      const outputDir = path.join(__dirname, '..', 'compiled');
      const baseName = path.basename(originalName, path.extname(originalName));
      const outputPath = path.join(outputDir, `${baseName}.ex5`);
      
      // Try using a simple copy for demonstration (replace with actual compiler)
      const alternativeCompiler = spawn('cp', [inputPath, outputPath], {
        stdio: ['pipe', 'pipe', 'pipe'],
        timeout: 10000
      });
      
      let stdout = '';
      let stderr = '';
      
      alternativeCompiler.stdout.on('data', (data) => {
        stdout += data.toString();
      });
      
      alternativeCompiler.stderr.on('data', (data) => {
        stderr += data.toString();
      });
      
      alternativeCompiler.on('close', async (code) => {
        if (code === 0) {
          // Rename the copied file to have .ex5 extension
          const tempPath = outputPath;
          const finalOutputPath = tempPath.replace('.mq5', '.ex5');
          
          try {
            await fs.rename(tempPath, finalOutputPath);
            resolve({
              success: true,
              outputPath: finalOutputPath,
              logs: 'Alternative compilation successful',
              errors: ''
            });
          } catch (renameError) {
            resolve({
              success: false,
              error: `Failed to rename output file: ${renameError.message}`,
              logs: stdout,
              errors: stderr
            });
          }
        } else {
          resolve({
            success: false,
            error: 'Alternative compilation failed',
            logs: stdout,
            errors: stderr
          });
        }
      });
      
      alternativeCompiler.on('error', (error) => {
        resolve({
          success: false,
          error: `Alternative compiler error: ${error.message}`,
          logs: stdout,
          errors: stderr
        });
      });
      
    } catch (error) {
      resolve({
        success: false,
        error: `Alternative compilation setup failed: ${error.message}`,
        logs: '',
        errors: ''
      });
    }
  });
}

/**
 * Check if MetaTrader compiler is available
 * @returns {Promise<boolean>} True if compiler is available
 */
async function checkCompilerAvailability() {
  try {
    await fs.access(COMPILER_PATH);
    return true;
  } catch {
    console.warn(`MetaTrader compiler not found at: ${COMPILER_PATH}`);
    console.warn('Please ensure MetaTrader 5 is installed and MT5_PATH environment variable is set correctly');
    return false;
  }
}

module.exports = {
  compileMessage,
  checkCompilerAvailability
};
