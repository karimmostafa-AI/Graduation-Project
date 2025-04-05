require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const cookieParser = require('cookie-parser');
const cors = require('cors');
const path = require('path');
const pool = require('./db'); // Use the pool from db.js
const fs = require('fs');

process.env.PGCLIENTENCODING = 'UTF8';

const app = express();
const port = process.env.PORT || 5000;

// Ensure uploads directory exists
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)){
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// Configure CORS
const corsOptions = {
  origin: [
    'http://localhost:3000',   // Next.js development server
    'http://127.0.0.1:3000',
    'http://localhost:5000',   // If frontend is served from Express
    'http://127.0.0.1:5000',
    'http://192.168.1.9:3000',
    'http://192.168.1.9:5000',
  ],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  preflightContinue: false,
  optionsSuccessStatus: 204
};

app.use(cors(corsOptions));
app.use(bodyParser.json());
app.use(cookieParser());

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

// Simple route to test DB connection
app.get('/', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW()');
    res.send(`Server Running. PostgreSQL Time: ${result.rows[0].now}`);
  } catch (err) {
    console.error('DB Error:', err);
    res.status(500).send('Database connection error');
  }
});

app.listen(port,'0.0.0.0', () => {
  console.log(`Server running on http://localhost:${port}`);
  console.log(`Also accessible at http://0.0.0.0:${port}`);
  console.log('Environment:', process.env.NODE_ENV);
});
