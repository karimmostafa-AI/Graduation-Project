// middleware/upload.js
const multer = require('multer');
const path = require('path');

// Configure storage settings
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    // Ensure the 'uploads' folder exists in your project root
    cb(null, 'uploads/');
  },
  filename: function (req, file, cb) {
    // Create a unique filename: current timestamp plus a random number
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, uniqueSuffix + path.extname(file.originalname));
  }
});

// Allow all file types by not specifying any filter
// Just adding a basic size limit for security
const upload = multer({ 
  storage,
  limits: {
    fileSize: 20 * 1024 * 1024 // 20MB limit
  }
});

module.exports = upload;