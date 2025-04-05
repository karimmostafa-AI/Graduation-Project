require('dotenv').config();
const fs = require('fs').promises;
const path = require('path');
const { Pool } = require('pg');

const pool = new Pool({
  user: 'postgres',
  password: '1352001',
  host: 'localhost',
  port: 5432,
  database: 'web3'
});

async function runMigration() {
  let client;
  try {
    client = await pool.connect();
    
    // Create migrations table if it doesn't exist
    await client.query(`
      CREATE TABLE IF NOT EXISTS migrations (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Read all SQL files from migrations directory
    const migrationsDir = path.join(__dirname, '..', 'migrations');
    const files = await fs.readdir(migrationsDir);
    const sqlFiles = files.filter(f => f.endsWith('.sql'));

    // Get already executed migrations
    const { rows } = await client.query('SELECT name FROM migrations');
    const executedMigrations = new Set(rows.map(r => r.name));

    // Run migrations in transaction
    for (const file of sqlFiles) {
      if (executedMigrations.has(file)) {
        console.log(`Migration ${file} already executed, skipping...`);
        continue;
      }

      console.log(`Running migration: ${file}`);
      const sql = await fs.readFile(path.join(migrationsDir, file), 'utf8');
      
      await client.query('BEGIN');
      try {
        await client.query(sql);
        await client.query('INSERT INTO migrations (name) VALUES ($1)', [file]);
        await client.query('COMMIT');
        console.log(`Migration ${file} completed successfully`);
      } catch (err) {
        await client.query('ROLLBACK');
        throw err;
      }
    }

    console.log('All migrations completed successfully');
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  } finally {
    if (client) {
      client.release();
    }
    await pool.end();
  }
}

runMigration();
