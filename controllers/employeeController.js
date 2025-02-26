const pool = require('../db');
const bcrypt = require('bcrypt');

exports.getEmployees = async (req, res) => {
  try {
    // First check if table exists
    const tableCheck = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 'employees'
      );
    `);

    if (!tableCheck.rows[0].exists) {
      // Create the employees table if it doesn't exist
      await pool.query(`
        CREATE TABLE IF NOT EXISTS employees (
          employee_id SERIAL PRIMARY KEY,
          username VARCHAR(50) UNIQUE NOT NULL,
          password_hash VARCHAR(255) NOT NULL,
          active BOOLEAN DEFAULT true,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      `);
    }

    // Get all active employees
    const result = await pool.query(`
      SELECT 
        employee_id,
        username,
        active,
        created_at
      FROM employees 
      WHERE active = true
      ORDER BY created_at DESC
    `);

    console.log('Fetched employees:', result.rows); // Debug log
    
    res.json({ 
      success: true,
      employees: result.rows 
    });
  } catch (error) {
    console.error('Detailed error in getEmployees:', error);
    res.status(500).json({ 
      error: 'Internal server error',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

exports.addEmployee = async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ error: 'Username and password are required' });
  }

  try {
    // Check if username already exists
    const checkExisting = await pool.query(
      'SELECT username FROM employees WHERE username = $1',
      [username]
    );

    if (checkExisting.rows.length > 0) {
      return res.status(409).json({ error: 'Username already exists' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const result = await pool.query(
      `INSERT INTO employees (username, password_hash)
       VALUES ($1, $2)
       RETURNING employee_id, username, active, created_at`,
      [username, hashedPassword]
    );

    res.status(201).json({
      success: true,
      employee: result.rows[0]
    });
  } catch (error) {
    console.error('Error adding employee:', error);
    res.status(500).json({ 
      error: 'Internal server error',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

exports.removeEmployee = async (req, res) => {
  const { id } = req.params;
  
  if (!id) {
    return res.status(400).json({ error: 'Employee ID is required' });
  }

  try {
    const result = await pool.query(
      'UPDATE employees SET active = false WHERE employee_id = $1 RETURNING employee_id',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Employee not found' });
    }

    res.json({
      success: true,
      message: 'Employee removed successfully',
      employee_id: result.rows[0].employee_id
    });
  } catch (error) {
    console.error('Error removing employee:', error);
    res.status(500).json({ 
      error: 'Internal server error',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};
