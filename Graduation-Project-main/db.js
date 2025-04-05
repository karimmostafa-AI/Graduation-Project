// db.js
const { Pool } = require('pg');

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || '1352001',
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'web3'
});

// Add error listener
pool.on('error', (err) => {
  console.error('Unexpected error on idle database client', err);
});

// Test connection and log column sizes
pool.query(`
  SELECT column_name, character_maximum_length 
  FROM information_schema.columns 
  WHERE table_name = 'property_requests'
`, (err, res) => {
  if (err) {
    console.error('Database connection error:', err);
  } else {
    console.log('Database column specifications:', res.rows);
  }
});

module.exports = pool;
