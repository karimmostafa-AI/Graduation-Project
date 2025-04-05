require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const cookieParser = require('cookie-parser');
const cors = require('cors');
const path = require('path');
const pool = require('./db'); // Use the pool from db.js
const fs = require('fs');

const app = express();
const port = process.env.PORT || 5000;

// Ensure uploads directory exists
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)){
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// Update CORS configuration
const corsOptions = {
  origin: 'http://localhost:3000',
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  preflightContinue: false,
  optionsSuccessStatus: 204
};

app.use(cors(corsOptions));

app.use(express.json());
app.use(cookieParser());
app.use(express.static('uploads'));

// Add more explicit headers
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Credentials', 'true');
  res.header('Access-Control-Allow-Origin', 'http://localhost:3000');
  res.header('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,PATCH,OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  
  if (req.method === 'OPTIONS') {
    return res.status(204).end();
  }
  next();
});

// Add login attempt logging middleware
app.use((req, res, next) => {
  if (req.path === '/api/auth/login' && req.method === 'POST') {
    console.log('Login attempt:', req.body);
  }
  next();
});

// Serve static files from uploads directory
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Import and mount routes
const apiRoutes = require('./routes/routes');
app.use('/api', apiRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(err.status || 500).json({
    error: process.env.NODE_ENV === 'development' ? err.message : 'Internal server error'
  });
});

// Handle 404
app.use((req, res) => {
  res.status(404).json({ error: 'Not Found' });
});

// Add a health check endpoint
app.get('/', (req, res) => {
  res.json({ status: 'ok', message: 'Server is running' });
});

// Add this before app.listen
const checkDatabaseSchema = async () => {
  try {
    await pool.query(`
      DO $$ 
      BEGIN
        ALTER TABLE property_requests 
        ALTER COLUMN seller_wallet_address TYPE VARCHAR(100),
        ALTER COLUMN buyer_wallet_address TYPE VARCHAR(100);
      EXCEPTION
        WHEN others THEN NULL;
      END $$;
    `);
    console.log('Database schema checked and updated if needed');
  } catch (error) {
    console.error('Database schema check failed:', error);
  }
};

// Update your server startup
const startServer = async () => {
  await checkDatabaseSchema();
  app.listen(port, () => {
    console.log(`Server running on http://localhost:${port}`);
  });
};

startServer();
