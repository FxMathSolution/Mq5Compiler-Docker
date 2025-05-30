const express = require('express');
const multer = require('multer');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const path = require('path');
const fs = require('fs').promises;
const { compileMessage } = require('./compiler');
const { validateFile, cleanupFile } = require('./utils/fileHandler');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());
app.use(cors());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use(limiter);

// Create directories if they don't exist
const createDirectories = async () => {
  const dirs = ['uploads', 'compiled', 'temp'];
  for (const dir of dirs) {
    try {
      await fs.mkdir(path.join(__dirname, '..', dir), { recursive: true });
    } catch (error) {
      console.error(`Error creating directory ${dir}:`, error);
    }
  }
};

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, '..', 'uploads'));
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, `${uniqueSuffix}-${file.originalname}`);
  }
});

const upload = multer({
  storage: storage,
  fileFilter: (req, file, cb) => {
    if (file.mimetype === 'application/octet-stream' || 
        file.originalname.endsWith('.mq5') || 
        file.originalname.endsWith('.mq4')) {
      cb(null, true);
    } else {
      cb(new Error('Only .mq5 and .mq4 files are allowed'), false);
    }
  },
  limits: {
    fileSize: 10 * 1024 * 1024 // 10MB limit
  }
});

// Middleware
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Compile endpoint
app.post('/compile', upload.single('mq5file'), async (req, res) => {
  let uploadedFilePath = null;
  let compiledFilePath = null;

  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    uploadedFilePath = req.file.path;
    console.log(`Received file: ${req.file.originalname}`);

    // Validate file
    const isValid = await validateFile(uploadedFilePath);
    if (!isValid) {
      return res.status(400).json({ error: 'Invalid MQ5 file format' });
    }

    // Compile the file
    const compilationResult = await compileMessage(uploadedFilePath, req.file.originalname);
    
    if (!compilationResult.success) {
      return res.status(400).json({ 
        error: 'Compilation failed', 
        details: compilationResult.error,
        logs: compilationResult.logs 
      });
    }

    compiledFilePath = compilationResult.outputPath;

    // Check if compiled file exists
    try {
      await fs.access(compiledFilePath);
    } catch {
      return res.status(500).json({ error: 'Compiled file not found' });
    }

    // Send the compiled file
    res.download(compiledFilePath, (err) => {
      if (err) {
        console.error('Error sending file:', err);
        if (!res.headersSent) {
          res.status(500).json({ error: 'Error sending compiled file' });
        }
      }
      
      // Cleanup files after sending
      cleanupFile(uploadedFilePath);
      cleanupFile(compiledFilePath);
    });

  } catch (error) {
    console.error('Compilation error:', error);
    
    // Cleanup on error
    if (uploadedFilePath) cleanupFile(uploadedFilePath);
    if (compiledFilePath) cleanupFile(compiledFilePath);
    
    if (!res.headersSent) {
      res.status(500).json({ error: 'Internal server error', details: error.message });
    }
  }
});

// Batch compile endpoint
app.post('/compile-batch', upload.array('mq5files', 10), async (req, res) => {
  if (!req.files || req.files.length === 0) {
    return res.status(400).json({ error: 'No files uploaded' });
  }

  const results = [];
  const compiledFiles = [];

  try {
    for (const file of req.files) {
      try {
        const isValid = await validateFile(file.path);
        if (!isValid) {
          results.push({
            filename: file.originalname,
            success: false,
            error: 'Invalid file format'
          });
          continue;
        }

        const compilationResult = await compileMessage(file.path, file.originalname);
        
        if (compilationResult.success) {
          compiledFiles.push({
            originalName: file.originalname,
            compiledPath: compilationResult.outputPath
          });
          results.push({
            filename: file.originalname,
            success: true,
            outputFile: path.basename(compilationResult.outputPath)
          });
        } else {
          results.push({
            filename: file.originalname,
            success: false,
            error: compilationResult.error,
            logs: compilationResult.logs
          });
        }
      } catch (error) {
        results.push({
          filename: file.originalname,
          success: false,
          error: error.message
        });
      } finally {
        cleanupFile(file.path);
      }
    }

    res.json({
      message: 'Batch compilation completed',
      results: results,
      totalFiles: req.files.length,
      successfulCompilations: results.filter(r => r.success).length
    });

    // Cleanup compiled files after a delay
    setTimeout(() => {
      compiledFiles.forEach(file => cleanupFile(file.compiledPath));
    }, 60000); // 1 minute delay

  } catch (error) {
    console.error('Batch compilation error:', error);
    
    // Cleanup uploaded files
    req.files.forEach(file => cleanupFile(file.path));
    
    res.status(500).json({ error: 'Batch compilation failed', details: error.message });
  }
});

// Error handling middleware
app.use((error, req, res, next) => {
  if (error instanceof multer.MulterError) {
    if (error.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({ error: 'File too large' });
    }
  }
  
  console.error('Unhandled error:', error);
  res.status(500).json({ error: 'Internal server error' });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// Start server
const startServer = async () => {
  await createDirectories();
  
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`MQ5 Compiler Service running on port ${PORT}`);
    console.log(`Health check: http://localhost:${PORT}/health`);
  });
};

startServer().catch(console.error);

module.exports = app;
