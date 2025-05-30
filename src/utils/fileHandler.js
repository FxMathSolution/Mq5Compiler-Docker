const fs = require('fs').promises;
const path = require('path');

/**
 * Validate if the uploaded file is a valid MQ5/MQ4 file
 * @param {string} filePath - Path to the uploaded file
 * @returns {Promise<boolean>} True if valid
 */
async function validateFile(filePath) {
  try {
    const content = await fs.readFile(filePath, 'utf8');
    
    // Check for basic MQ5/MQ4 syntax
    const hasValidSyntax = 
      content.includes('#property') ||
      content.includes('OnInit') ||
      content.includes('OnTick') ||
      content.includes('OnStart') ||
      content.includes('input ') ||
      content.includes('extern ');
    
    // Check file extension
    const ext = path.extname(filePath).toLowerCase();
    const hasValidExtension = ext === '.mq5' || ext === '.mq4';
    
    return hasValidSyntax && hasValidExtension;
  } catch (error) {
    console.error('File validation error:', error);
    return false;
  }
}

/**
 * Clean up temporary files
 * @param {string} filePath - Path to the file to be deleted
 */
async function cleanupFile(filePath) {
  try {
    if (filePath) {
      await fs.unlink(filePath);
      console.log(`Cleaned up file: ${filePath}`);
    }
  } catch (error) {
    console.error(`Error cleaning up file ${filePath}:`, error);
  }
}

/**
 * Get file size in a human readable format
 * @param {number} bytes - File size in bytes
 * @returns {string} Human readable file size
 */
function formatFileSize(bytes) {
  if (bytes === 0) return '0 Bytes';
  
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

/**
 * Create a unique filename
 * @param {string} originalName - Original filename
 * @returns {string} Unique filename
 */
function createUniqueFilename(originalName) {
  const timestamp = Date.now();
  const random = Math.round(Math.random() * 1E9);
  const ext = path.extname(originalName);
  const name = path.basename(originalName, ext);
  
  return `${name}-${timestamp}-${random}${ext}`;
}

/**
 * Check if directory exists, create if not
 * @param {string} dirPath - Directory path
 */
async function ensureDirectoryExists(dirPath) {
  try {
    await fs.mkdir(dirPath, { recursive: true });
  } catch (error) {
    console.error(`Error creating directory ${dirPath}:`, error);
    throw error;
  }
}

/**
 * Get file stats
 * @param {string} filePath - Path to the file
 * @returns {Promise<Object>} File statistics
 */
async function getFileStats(filePath) {
  try {
    const stats = await fs.stat(filePath);
    return {
      size: stats.size,
      sizeFormatted: formatFileSize(stats.size),
      created: stats.birthtime,
      modified: stats.mtime,
      isFile: stats.isFile(),
      isDirectory: stats.isDirectory()
    };
  } catch (error) {
    console.error(`Error getting file stats for ${filePath}:`, error);
    return null;
  }
}

/**
 * Clean up old files in a directory
 * @param {string} dirPath - Directory path
 * @param {number} maxAgeMs - Maximum age in milliseconds
 */
async function cleanupOldFiles(dirPath, maxAgeMs = 3600000) { // 1 hour default
  try {
    const files = await fs.readdir(dirPath);
    const now = Date.now();
    
    for (const file of files) {
      const filePath = path.join(dirPath, file);
      const stats = await fs.stat(filePath);
      
      if (now - stats.mtime.getTime() > maxAgeMs) {
        await fs.unlink(filePath);
        console.log(`Cleaned up old file: ${filePath}`);
      }
    }
  } catch (error) {
    console.error(`Error cleaning up old files in ${dirPath}:`, error);
  }
}

module.exports = {
  validateFile,
  cleanupFile,
  formatFileSize,
  createUniqueFilename,
  ensureDirectoryExists,
  getFileStats,
  cleanupOldFiles
};
