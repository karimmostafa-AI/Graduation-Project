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

// Filter to allow only PDF files
const fileFilter = (req, file, cb) => {
  if (file.mimetype === 'application/pdf') {
    cb(null, true);
  } else {
    cb(new Error('Only PDF files are allowed!'), false);
  }
};

const upload = multer({ storage, fileFilter });

module.exports = upload;
