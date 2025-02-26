// db.js
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://your_username:your_password@localhost:5432/gov_property_verification'
});

module.exports = pool;
