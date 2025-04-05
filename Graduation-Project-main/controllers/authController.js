// controllers/authController.js

const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const pool = require('../db'); // our PostgreSQL pool from the previous step

// Ensure you set a JWT secret in your environment variables
const JWT_SECRET = process.env.JWT_SECRET;
const JWT_EXPIRES_IN = '1h';  // Adjust as needed
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'refresh-secret';

// Signup endpoint for mobile app users (adjust table as necessary)
exports.signup = async (req, res) => {
  try {
    const { username, password, wallet_address, national_id } = req.body;
    if (!username || !password || !wallet_address || !national_id) {
      return res.status(400).json({ error: 'Missing required fields' });
    }
    
    // Check if user already exists (including wallet_address)
    const checkUser = await pool.query(
      'SELECT username, national_id, wallet_address FROM mobile_app_users WHERE username = $1 OR national_id = $2 OR wallet_address = $3',
      [username, national_id, wallet_address]
    );

    if (checkUser.rows.length > 0) {
      const existing = checkUser.rows[0];
      if (existing.username === username) {
        return res.status(409).json({ error: 'Username already exists' });
      }
      if (existing.national_id === national_id) {
        return res.status(409).json({ error: 'National ID already registered' });
      }
      if (existing.wallet_address === wallet_address) {
        return res.status(409).json({ error: 'Wallet address already registered' });
      }
    }

    // Hash the password
    const saltRounds = 10;
    const password_hash = await bcrypt.hash(password, saltRounds);

    // Insert into mobile_app_users table with national_id
    const query = `
      INSERT INTO mobile_app_users (username, password_hash, wallet_address, national_id)
      VALUES ($1, $2, $3, $4)
      RETURNING user_id, username, wallet_address, national_id, created_at;
    `;
    const values = [username, password_hash, wallet_address, national_id];
    const result = await pool.query(query, values);
    const user = result.rows[0];

    // Create JWT token
    const token = jwt.sign(
      { 
        user_id: user.user_id, 
        role: 'mobile_app_user',
        wallet_address: user.wallet_address 
      },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );
    // Set token in HttpOnly cookie
    res.cookie('token', token, { httpOnly: true, secure: process.env.NODE_ENV === 'production' });

    res.status(201).json({ message: 'Signup successful', user });
  } catch (error) {
    console.error('Signup error:', error);
    if (error.code === '23505') { // PostgreSQL unique violation error code
      if (error.constraint === 'mobile_app_users_national_id_key') {
        return res.status(409).json({ error: 'National ID already registered' });
      }
      if (error.constraint === 'mobile_app_users_username_key') {
        return res.status(409).json({ error: 'Username already exists' });
      }
      if (error.constraint === 'mobile_app_users_wallet_address_key') {
        return res.status(409).json({ error: 'Wallet address already registered' });
      }
    }
    res.status(500).json({ error: 'Internal server error' });
  }
};

exports.login = async (req, res) => {
  try {
    const { username, password } = req.body;
    
    if (!username || !password) {
      return res.status(400).json({ error: 'Username and password are required' });
    }

    const cleanUsername = username.trim();
    console.log('Login attempt:', { username: cleanUsername }); // Debug log

    // First check special admin credentials
    if (cleanUsername === process.env.ADMIN_USERNAME && password === process.env.ADMIN_PASSWORD) {
      const token = jwt.sign(
        { user_id: 'admin', role: 'admin', username: cleanUsername },
        JWT_SECRET,
        { expiresIn: JWT_EXPIRES_IN }
      );
      
      res.cookie('token', token, { 
        httpOnly: true, 
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'lax'
      });
      
      return res.json({
        message: 'Admin login successful',
        user: { user_id: 'admin', username: cleanUsername, role: 'admin' }
      });
    }

    // Check managers
    let query = `
      SELECT manager_id, username, password_hash 
      FROM managers 
      WHERE LOWER(username) = LOWER($1) AND active = true
    `;
    let result = await pool.query(query, [cleanUsername]);

    if (result.rows.length > 0) {
      const user = result.rows[0];
      const isValid = await bcrypt.compare(password, user.password_hash);
      
      if (isValid) {
        const token = jwt.sign(
          { 
            user_id: user.manager_id, 
            role: 'manager',
            username: user.username 
          },
          JWT_SECRET,
          { expiresIn: JWT_EXPIRES_IN }
        );
        
        res.cookie('token', token, { 
          httpOnly: true, 
          secure: process.env.NODE_ENV === 'production',
          sameSite: 'lax'
        });
        
        return res.json({
          message: 'Login successful',
          user: { 
            user_id: user.manager_id, 
            username: user.username,
            role: 'manager'
          }
        });
      }
    }

    // Check employees
    query = `
      SELECT employee_id, username, password_hash 
      FROM employees 
      WHERE LOWER(username) = LOWER($1) AND active = true
    `;
    result = await pool.query(query, [cleanUsername]);

    if (result.rows.length > 0) {
      const user = result.rows[0];
      const isValid = await bcrypt.compare(password, user.password_hash);
      
      if (isValid) {
        const token = jwt.sign(
          { 
            user_id: user.employee_id, 
            role: 'employee',
            username: user.username 
          },
          JWT_SECRET,
          { expiresIn: JWT_EXPIRES_IN }
        );
        
        res.cookie('token', token, { 
          httpOnly: true, 
          secure: process.env.NODE_ENV === 'production',
          sameSite: 'lax'
        });
        
        return res.json({
          message: 'Login successful',
          user: { 
            user_id: user.employee_id, 
            username: user.username,
            role: 'employee'
          }
        });
      }
    }

    // Finally check mobile app users
    query = `
      SELECT user_id, username, password_hash, wallet_address, national_id 
      FROM mobile_app_users 
      WHERE LOWER(username) = LOWER($1) AND active = true
    `;
    result = await pool.query(query, [cleanUsername]);

    // For successful login, create both access and refresh tokens
    const createTokens = (userData) => {
      const accessToken = jwt.sign(userData, JWT_SECRET, { expiresIn: '1h' });
      const refreshToken = jwt.sign(userData, JWT_REFRESH_SECRET, { expiresIn: '7d' });
      return { accessToken, refreshToken };
    };

    // Handle mobile app users login
    if (result.rows.length > 0) {
      const user = result.rows[0];
      const isValid = await bcrypt.compare(password, user.password_hash);
      
      if (isValid) {
        const { accessToken, refreshToken } = createTokens({
          user_id: user.user_id,
          role: 'mobile_app_user',
          wallet_address: user.wallet_address
        });
        
        // Set both tokens in cookies
        res.cookie('token', accessToken, {
          httpOnly: true,
          secure: process.env.NODE_ENV === 'production',
          sameSite: 'lax'
        });
        
        res.cookie('refreshToken', refreshToken, {
          httpOnly: true,
          secure: process.env.NODE_ENV === 'production',
          sameSite: 'lax'
        });
        
        return res.json({
          message: 'Login successful',
          user: {
            user_id: user.user_id,
            username: user.username,
            wallet_address: user.wallet_address,
            role: 'mobile_app_user'
          }
        });
      }
    }

    // No valid user found or password incorrect
    return res.status(401).json({ error: 'Invalid credentials' });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ 
      error: 'Internal server error',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined 
    });
  }
};

// Update logout to clear both tokens
exports.logout = (req, res) => {
  res.clearCookie('token');
  res.clearCookie('refreshToken');
  res.json({ message: 'Logged out successfully' });
};
