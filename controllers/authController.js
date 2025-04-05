// controllers/authController.js

const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const pool = require('../db'); // our PostgreSQL pool from the previous step
const { getMissingFields } = require('../utils/validation');
const { Wallet } = require('ethers'); // Add ethers import at the top of the file

// Ensure you set a JWT secret in your environment variables
const JWT_SECRET = process.env.JWT_SECRET;
const JWT_EXPIRES_IN = '1h';  // Adjust as needed

// Signup endpoint for mobile app users - modified to allow duplicate usernames
exports.signup = async (req, res) => {
  try {
    console.log('Request body:', req.body);

    const requiredFields = ['username', 'password', 'national_id', 'email', 'phone_number'];
    const missing = getMissingFields(req.body, requiredFields);
    
    if (missing.length > 0) {
      return res.status(400).json({ 
        error: 'Missing required fields', 
        missingFields: missing 
      });
    }
    
    // Now including phone_number
    const { username, password, national_id, email, phone_number } = req.body;
    console.log('Extracted values:', { username, password: '***', national_id, email, phone_number });
    
    // Generate a new wallet address automatically
    const wallet = Wallet.createRandom();
    const wallet_address = wallet.address;
    console.log('Generated wallet address:', wallet_address);
    
    // MODIFIED: Check if user already exists - removed username uniqueness check
    const checkUser = await pool.query(
      'SELECT national_id, email, phone_number FROM mobile_app_users WHERE national_id = $1 OR email = $2 OR phone_number = $3',
      [national_id, email, phone_number] // Username removed from params
    );

    if (checkUser.rows.length > 0) {
      const existing = checkUser.rows[0];
      // REMOVED: Username uniqueness check
      // if (existing.username === username) {
      //   return res.status(409).json({ error: 'Username already exists' });
      // }
      
      if (existing.national_id === national_id) {
        return res.status(409).json({ error: 'National ID already registered' });
      }
      if (existing.email === email) {
        return res.status(409).json({ error: 'Email already registered' });
      }
      if (existing.phone_number === phone_number) {
        return res.status(409).json({ error: 'Phone number already registered' });
      }
    }

    // Hash the password
    const saltRounds = 10;
    const password_hash = await bcrypt.hash(password, saltRounds);

    // Insert with wallet_address and phone_number
    const query = `
      INSERT INTO mobile_app_users (username, password_hash, national_id, email, phone_number, wallet_address)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING user_id, username, national_id, email, phone_number, wallet_address, created_at;
    `;
    const values = [username, password_hash, national_id, email, phone_number, wallet_address];
    console.log('Query values:', { username, password_hash: '***', national_id, email, phone_number, wallet_address });
    
    const result = await pool.query(query, values);
    const user = result.rows[0];

    // Include wallet_address in JWT token
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

    res.status(201).json({ 
      message: 'Signup successful', 
      user: {
        ...user,
        wallet_address: user.wallet_address
      }
    });
  } catch (error) {
    console.error('Signup error:', error);
    if (error.code === '23505') { // PostgreSQL unique violation error code
      if (error.constraint === 'mobile_app_users_national_id_key') {
        return res.status(409).json({ error: 'National ID already registered' });
      }
      // REMOVED: Username uniqueness constraint check
      // if (error.constraint === 'mobile_app_users_username_key') {
      //   return res.status(409).json({ error: 'Username already exists' });
      // }
      if (error.constraint === 'mobile_app_users_email_key') {
        return res.status(409).json({ error: 'Email already registered' });
      }
      if (error.constraint === 'mobile_app_users_wallet_address_key') {
        return res.status(409).json({ error: 'Wallet address already exists (rare collision)' });
      }
    }
    res.status(500).json({ error: 'Internal server error' });
  }
};

exports.login = async (req, res) => {
  try {
    console.log('Full request body:', req.body);
    
    // Support both username and national_id for login
    const { username, password, national_id } = req.body;
    
    if (!password || (!username && !national_id)) {
      return res.status(400).json({ 
        error: 'Missing required fields', 
        missingFields: !password ? ['password'] : ['username or national_id']
      });
    }
    
    const loginIdentifier = username || national_id;
    const cleanIdentifier = loginIdentifier.trim();
    
    console.log('Login attempt with:', { identifier: cleanIdentifier });

    // First check special admin credentials
    if (cleanIdentifier === process.env.ADMIN_USERNAME && password === process.env.ADMIN_PASSWORD) {
      const token = jwt.sign(
        { user_id: 'admin', role: 'admin', national_id: cleanIdentifier },
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
        user: { user_id: 'admin', national_id: cleanIdentifier, role: 'admin' }
      });
    }

    // Check managers
    let query = `
      SELECT manager_id, username, password_hash 
      FROM managers 
      WHERE LOWER(username) = LOWER($1) AND active = true
    `;
    let result = await pool.query(query, [cleanIdentifier]);

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
    result = await pool.query(query, [cleanIdentifier]);

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

    // Fix the mobile app users query in the login function
    query = `
      SELECT user_id, username, password_hash, national_id, phone_number, wallet_address 
      FROM mobile_app_users 
      WHERE (national_id = $1 OR username = $1) AND active = true
    `;
    result = await pool.query(query, [cleanIdentifier]);

    if (result.rows.length > 0) {
      const user = result.rows[0];
      const isValid = await bcrypt.compare(password, user.password_hash);
      
      if (isValid) {
        const token = jwt.sign(
          { 
            user_id: user.user_id, 
            role: 'mobile_app_user',
            wallet_address: user.wallet_address  // Include wallet_address in token
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

exports.logout = (req, res) => {
  // Clear the token cookie
  res.clearCookie('token');
  res.json({ message: 'Logged out successfully' });
};

// Get current user's wallet address
exports.getWalletAddress = async (req, res) => {
  try {
    // The wallet_address should be available in the JWT token
    const userWalletAddress = req.user.wallet_address;
    
    if (!userWalletAddress) {
      return res.status(404).json({ 
        success: false,
        error: 'Wallet address not found for this user' 
      });
    }
    
    return res.json({
      success: true,
      wallet_address: userWalletAddress
    });
  } catch (error) {
    console.error('Error fetching wallet address:', error);
    return res.status(500).json({ 
      success: false,
      error: 'Internal server error',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};
