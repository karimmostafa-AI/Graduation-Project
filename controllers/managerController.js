const pool = require('../db');
const bcrypt = require('bcrypt');

exports.getManagers = async (req, res) => {
  try {
    // First, check if the table exists and has the required columns
    const checkTable = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_name = 'managers' 
        AND column_name = 'active'
      );
    `);

    if (!checkTable.rows[0].exists) {
      throw new Error('Database schema is not properly set up');
    }

    const result = await pool.query(`
      SELECT 
        manager_id as id, 
        username, 
        active, 
        created_at,
        updated_at
      FROM managers 
      WHERE active = true
      ORDER BY created_at DESC
    `);
    
    res.json({ 
      success: true,
      managers: result.rows 
    });
  } catch (error) {
    console.error('Error fetching managers:', error);
    res.status(500).json({ 
      error: 'Internal server error',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

exports.addManager = async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ error: 'Username and password are required' });
  }

  try {
    // Check if username already exists
    const checkExisting = await pool.query(
      'SELECT username FROM managers WHERE username = $1',
      [username]
    );

    if (checkExisting.rows.length > 0) {
      return res.status(409).json({ error: 'Username already exists' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Insert new manager
    const result = await pool.query(
      `INSERT INTO managers (username, password_hash)
       VALUES ($1, $2)
       RETURNING manager_id as id, username, active, created_at`,
      [username, hashedPassword]
    );

    res.status(201).json({
      success: true,
      manager: result.rows[0]
    });
  } catch (error) {
    console.error('Error adding manager:', error);
    res.status(500).json({ 
      error: 'Internal server error',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

exports.requestManagerRemoval = async (req, res) => {
  const { id } = req.params;
  
  if (!id) {
    return res.status(400).json({ error: 'Manager ID is required' });
  }

  try {
    const result = await pool.query(
      'UPDATE managers SET active = false WHERE manager_id = $1 RETURNING manager_id',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Manager not found' });
    }

    res.json({
      success: true,
      message: 'Manager removed successfully',
      manager_id: result.rows[0].manager_id
    });
  } catch (error) {
    console.error('Error removing manager:', error);
    res.status(500).json({ 
      error: 'Internal server error',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};
