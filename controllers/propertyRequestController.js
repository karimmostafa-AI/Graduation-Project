// controllers/propertyRequestController.js
const pool = require('../db');
const bcrypt = require('bcrypt');

// Create a new property request
exports.createRequest = async (req, res) => {
  try {
    const {
      seller_wallet_address,
      buyer_wallet_address,
      full_description,
      property_price,
    } = req.body;

    // Get the file path from multer
    const ownership_document = req.file ? req.file.path : null;

    if (!ownership_document) {
      return res.status(400).json({ error: 'Ownership document is required' });
    }

    // Begin transaction
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Helper function to create temporary user
      const createTempUser = async (walletAddress) => {
        const shortWallet = walletAddress.substring(2, 6);
        const timestamp = Date.now().toString().slice(-6);
        const tempUsername = `tmp_${shortWallet}_${timestamp}`;
        const tempPassword = await bcrypt.hash(walletAddress, 10);
        const tempNationalId = `TMP${timestamp}${shortWallet}`.slice(0, 14);

        await client.query(
          `INSERT INTO mobile_app_users (
            username, 
            password_hash, 
            wallet_address, 
            national_id
          ) VALUES ($1, $2, $3, $4)
          ON CONFLICT (wallet_address) DO NOTHING
          RETURNING user_id`,
          [tempUsername, tempPassword, walletAddress, tempNationalId]
        );
      };

      // Check and create seller if needed
      const sellerCheck = await client.query(
        'SELECT user_id FROM mobile_app_users WHERE wallet_address = $1',
        [seller_wallet_address]
      );

      if (sellerCheck.rows.length === 0) {
        await createTempUser(seller_wallet_address);
      }

      // Check and create buyer if needed
      const buyerCheck = await client.query(
        'SELECT user_id FROM mobile_app_users WHERE wallet_address = $1',
        [buyer_wallet_address]
      );

      if (buyerCheck.rows.length === 0) {
        await createTempUser(buyer_wallet_address);
      }

      // Create property request
      const query = `
        INSERT INTO property_requests (
          seller_wallet_address,
          buyer_wallet_address,
          full_description,
          property_price,
          ownership_document
        )
        VALUES ($1, $2, $3, $4, $5)
        RETURNING *;
      `;
      const values = [
        seller_wallet_address,
        buyer_wallet_address,
        full_description,
        property_price,
        ownership_document
      ];
      
      const result = await client.query(query, values);
      await client.query('COMMIT');
      
      return res.status(201).json({
        success: true,
        property: result.rows[0],
        message: 'Property request created successfully'
      });

    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  } catch (error) {
    console.error('Detailed error creating property request:', error);
    return res.status(500).json({ 
      error: 'Internal server error',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get all property requests (for employees to review)
exports.getAllRequests = async (req, res) => {
  try {
    const query = `
      SELECT 
        pr.*,
        mu_seller.username as seller_username,
        mu_buyer.username as buyer_username
      FROM property_requests pr
      LEFT JOIN mobile_app_users mu_seller ON pr.seller_wallet_address = mu_seller.wallet_address
      LEFT JOIN mobile_app_users mu_buyer ON pr.buyer_wallet_address = mu_buyer.wallet_address
      ORDER BY 
        CASE WHEN pr.status = 'pending' THEN 0
             WHEN pr.status = 'approved' THEN 1
             ELSE 2
        END,
        pr.created_at DESC
    `;
    
    const result = await pool.query(query);
    
    // Format the response data
    const requests = result.rows.map(row => ({
      ...row,
      property_price: parseFloat(row.property_price)
    }));

    return res.json({ 
      success: true,
      requests,
      summary: {
        total: requests.length,
        pending: requests.filter(r => r.status === 'pending').length,
        approved: requests.filter(r => r.status === 'approved').length,
        rejected: requests.filter(r => r.status === 'rejected').length
      }
    });
  } catch (error) {
    console.error('Error fetching property requests:', error);
    return res.status(500).json({ 
      error: 'Internal server error',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get property requests related to the logged-in user
exports.getUserRequests = async (req, res) => {
  try {
    // Assuming the JWT payload includes the user's phone_number now
    const userPhone = req.user.phone_number;
    const query = `
      SELECT *
      FROM property_requests
      WHERE seller_phone_number = $1 OR buyer_phone_number = $1
      ORDER BY created_at DESC
    `;
    const result = await pool.query(query, [userPhone]);
    return res.json({ requests: result.rows });
  } catch (error) {
    console.error('Error fetching user property requests:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

// Get property requests representing properties owned by the logged-in user
exports.getOwnedProperties = async (req, res) => {
  try {
    const userPhone = req.user.phone_number;
    
    if (!userPhone) {
      return res.status(400).json({ error: 'User phone number not found in token' });
    }

    // Modified query to use phone_number
    const query = `
      SELECT 
        pr.*,
        CASE 
          WHEN seller_phone_number = $1 THEN 'seller'
          WHEN buyer_phone_number = $1 THEN 'buyer'
        END as user_role
      FROM property_requests pr
      WHERE (
        (buyer_phone_number = $1 AND status = 'approved') OR
        (seller_phone_number = $1 AND status IN ('pending', 'approved'))
      )
      ORDER BY created_at DESC;
    `;

    const result = await pool.query(query, [userPhone]);
    
    // Group properties by user's role
    const properties = {
      owned: result.rows.filter(r => r.buyer_wallet_address === userWallet && r.status === 'approved'),
      selling: result.rows.filter(r => r.seller_wallet_address === userWallet),
    };

    return res.json({
      success: true,
      properties: result.rows,
      summary: {
        total: result.rows.length,
        owned: properties.owned.length,
        selling: properties.selling.length,
        approved: result.rows.filter(r => r.status === 'approved').length,
        pending: result.rows.filter(r => r.status === 'pending').length
      }
    });

  } catch (error) {
    console.error('Error fetching owned properties:', error);
    return res.status(500).json({ 
      error: 'Internal server error',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Update the status of a property request (for employee review)
exports.updateRequestStatus = async (req, res) => {
  try {
    const requestId = req.params.id ? parseInt(req.params.id, 10) : null;
    const { status } = req.body;

    if (!requestId || isNaN(requestId)) {
      return res.status(400).json({ error: 'Valid request ID is required' });
    }

    // Validate the status value
    if (!['approved', 'rejected'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status value' });
    }

    const query = `
      UPDATE property_requests
      SET status = $1, updated_at = now()
      WHERE request_id = $2
      RETURNING *;
    `;
    const result = await pool.query(query, [status, requestId]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Property request not found' });
    }
    
    return res.json({
      success: true,
      message: `Property request ${status}`,
      property: result.rows[0]
    });
  } catch (error) {
    console.error('Error updating property request status:', error);
    return res.status(500).json({ 
      error: 'Internal server error',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};
