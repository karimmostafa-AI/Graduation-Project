// middleware/authMiddleware.js

const jwt = require('jsonwebtoken');
const JWT_SECRET = process.env.JWT_SECRET;
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'refresh-secret';

const createNewToken = (userData) => {
  return jwt.sign(userData, JWT_SECRET, { expiresIn: '1h' });
};

const authMiddleware = (req, res, next) => {
  const token = req.cookies.token;
  const refreshToken = req.cookies.refreshToken;

  if (!token) {
    return res.status(401).json({ error: 'No token provided, unauthorized' });
  }
  
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError' && refreshToken) {
      try {
        // Verify refresh token
        const decoded = jwt.verify(refreshToken, JWT_REFRESH_SECRET);
        
        // Create new access token
        const newToken = createNewToken({
          user_id: decoded.user_id,
          role: decoded.role,
          wallet_address: decoded.wallet_address
        });

        // Set new access token in cookie
        res.cookie('token', newToken, {
          httpOnly: true,
          secure: process.env.NODE_ENV === 'production',
          sameSite: 'lax'
        });

        // Set user data and continue
        req.user = decoded;
        return next();
      } catch (refreshError) {
        console.error('Refresh token error:', refreshError);
        return res.status(401).json({ error: 'Session expired, please login again' });
      }
    }
    console.error('JWT verification error:', err);
    return res.status(401).json({ error: 'Token expired or invalid, please login again' });
  }
};

// Role-based middleware
authMiddleware.requireRole = (role) => {
  return (req, res, next) => {
    const token = req.cookies.token;
    console.log('Checking role:', role); // Debug role
    console.log('Cookie token:', token ? 'present' : 'missing'); // Debug token presence

    if (!token) {
      return res.status(401).json({ error: 'No token provided, unauthorized' });
    }

    try {
      const decoded = jwt.verify(token, JWT_SECRET);
      console.log('Decoded token:', { ...decoded, token: undefined }); // Debug decoded token

      if (decoded.role !== role) {
        console.log(`Role mismatch: expected ${role}, got ${decoded.role}`); // Debug role mismatch
        return res.status(403).json({ error: 'Insufficient permissions' });
      }
      req.user = decoded;
      next();
    } catch (err) {
      console.error('JWT verification error:', err);
      res.status(401).json({ error: 'Invalid token, unauthorized' });
    }
  };
};

// Multiple roles middleware
authMiddleware.requireRoles = (roles) => {
  return (req, res, next) => {
    const token = req.cookies.token;
    console.log('Checking roles:', roles);
    console.log('Cookie token:', token ? 'present' : 'missing');

    if (!token) {
      return res.status(401).json({ error: 'No token provided, unauthorized' });
    }

    try {
      const decoded = jwt.verify(token, JWT_SECRET);
      console.log('Decoded token:', { ...decoded, token: undefined });

      if (!roles.includes(decoded.role)) {
        console.log(`Role mismatch: expected one of ${roles}, got ${decoded.role}`);
        return res.status(403).json({ error: 'Insufficient permissions' });
      }
      req.user = decoded;
      next();
    } catch (err) {
      console.error('JWT verification error:', err);
      res.status(401).json({ error: 'Invalid token, unauthorized' });
    }
  };
};

module.exports = authMiddleware;
