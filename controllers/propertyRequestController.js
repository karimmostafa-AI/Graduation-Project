// controllers/propertyRequestController.js
const pool = require('../db');
const bcrypt = require('bcrypt');
const notificationController = require('./notificationController');

// Create a new property request
exports.createRequest = async (req, res) => {
  try {
    console.log("Received property request:", req.body);
    console.log("Property type from request:", req.body.property_type);
    
    const {
      seller_wallet_address,
      buyer_wallet_address,
      full_description,
      property_type,
      transaction_date,
      property_price,
      property_address,
    } = req.body;

    // Debug extracted value
    console.log("Extracted property_type:", property_type);

    // Get the file path from multer
    const ownership_document = req.file ? req.file.path : null;
    console.log("Ownership document path:", ownership_document);

    if (!ownership_document) {
      return res.status(400).json({ error: 'Ownership document is required' });
    }

    // Validate required fields
    if (!seller_wallet_address || !buyer_wallet_address || !full_description || !property_price) {
      return res.status(400).json({ 
        error: 'Missing required fields',
        required: ['seller_wallet_address', 'buyer_wallet_address', 'full_description', 'property_price'] 
      });
    }

    // Begin transaction
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Helper function to create temporary user
      const createTempUser = async (walletAddress) => {
        console.log("Creating temporary user with wallet:", walletAddress);
        
        const shortWallet = walletAddress.substring(0, 4);
        const timestamp = Date.now().toString().slice(-6);
        
        // Create temporary values
        const tempUsername = `tmp_${shortWallet}_${timestamp}`;
        const tempPassword = await bcrypt.hash(walletAddress, 10);
        const tempNationalId = `TMP${timestamp}${shortWallet}`.slice(0, 14);
        const tempEmail = `noreply_${shortWallet}_${timestamp}@example.com`;
        const tempPhone = `+1${timestamp}${shortWallet}`.slice(0, 15);

        // First check if user exists
        const userExistsResult = await client.query(
          'SELECT user_id FROM mobile_app_users WHERE wallet_address = $1',
          [walletAddress]
        );

        if (userExistsResult.rows.length === 0) {
          console.log("User doesn't exist. Creating new user with values:", {
            username: tempUsername,
            wallet: walletAddress,
            nationalId: tempNationalId,
            email: tempEmail,
            phone: tempPhone
          });
          
          // Insert user with all required fields
          const insertResult = await client.query(
            `INSERT INTO mobile_app_users (
              username, 
              password_hash, 
              wallet_address, 
              national_id,
              email,
              phone_number
            ) VALUES ($1, $2, $3, $4, $5, $6)
            RETURNING user_id`,
            [tempUsername, tempPassword, walletAddress, tempNationalId, tempEmail, tempPhone]
          );
          
          console.log("User created with ID:", insertResult.rows[0]?.user_id);
          return insertResult.rows[0]?.user_id;
        } else {
          console.log("User already exists with ID:", userExistsResult.rows[0].user_id);
          return userExistsResult.rows[0].user_id;
        }
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
          property_type,
          transaction_date,
          property_price,
          property_address,
          ownership_document
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING *;
      `;
      const values = [
        seller_wallet_address,
        buyer_wallet_address,
        full_description,
        property_type || 'unknown',  // Make sure this isn't null
        transaction_date || new Date(),
        property_price,
        property_address || null,
        ownership_document
      ];
      
      console.log("Executing insert with values:", {
        ...values,
        ownership_document: "file_path_here" // Don't log the full path
      });
      
      // Add more debugging to see exactly what's being inserted
      console.log("Property type being inserted:", property_type || 'unknown');
      
      const result = await client.query(query, values);
      await client.query('COMMIT');
      
      // Create notification for the buyer
      try {
        const notification = await notificationController.createNotification(
          buyer_wallet_address,
          'طلب عقد عقاري جديد',
          `لقد تلقيت طلبًا جديدًا لعقد عقاري: ${full_description.substring(0, 30)}...`,
          result.rows[0].request_id
        );
        console.log('Buyer notification created:', notification);
      } catch (notifErr) {
        console.error('Failed to create buyer notification:', notifErr);
        // Don't fail the request if notification creation fails
      }
      
      console.log("Property request created successfully");
      
      return res.status(201).json({
        success: true,
        property: result.rows[0],
        message: 'Property request created successfully'
      });

    } catch (err) {
      await client.query('ROLLBACK');
      console.error("Transaction error:", err);
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

// Create a sell contract with immediate ownership transfer
exports.createSellContract = async (req, res) => {
  try {
    console.log("Creating sell contract with direct ownership transfer:", req.body);
    
    const {
      seller_wallet_address,
      buyer_wallet_address,
      full_description,
      property_type,
      transaction_date,
      property_price,
      property_address,
    } = req.body;

    // Get the file path from multer
    const ownership_document = req.file ? req.file.path : null;
    console.log("Ownership document path:", ownership_document);

    if (!ownership_document) {
      return res.status(400).json({ error: 'Ownership document is required' });
    }

    // Validate required fields
    if (!seller_wallet_address || !buyer_wallet_address || !full_description || !property_price) {
      return res.status(400).json({ 
        error: 'Missing required fields',
        required: ['seller_wallet_address', 'buyer_wallet_address', 'full_description', 'property_price'] 
      });
    }

    // Begin transaction
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Check and create seller if needed
      const sellerCheck = await client.query(
        'SELECT user_id FROM mobile_app_users WHERE wallet_address = $1',
        [seller_wallet_address]
      );

      if (sellerCheck.rows.length === 0) {
        await createTempUser(client, seller_wallet_address);
      }

      // Check and create buyer if needed
      const buyerCheck = await client.query(
        'SELECT user_id FROM mobile_app_users WHERE wallet_address = $1',
        [buyer_wallet_address]
      );

      if (buyerCheck.rows.length === 0) {
        await createTempUser(client, buyer_wallet_address);
      }

      // Create property request with approved status
      const query = `
        INSERT INTO property_requests (
          seller_wallet_address,
          buyer_wallet_address,
          full_description,
          property_type,
          transaction_date,
          property_price,
          property_address,
          ownership_document,
          status
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        RETURNING *;
      `;
      const values = [
        seller_wallet_address,
        buyer_wallet_address,
        full_description,
        property_type || 'unknown',
        transaction_date || new Date(),
        property_price,
        property_address || null,
        ownership_document,
        'approved' // Set status to approved immediately
      ];
      
      console.log("Creating sell contract with values:", {
        ...values,
        ownership_document: "file_path_here"
      });
      
      const result = await client.query(query, values);
      await client.query('COMMIT');
      
      console.log("Sell contract created successfully with ownership transferred to buyer");
      
      return res.status(201).json({
        success: true,
        property: result.rows[0],
        message: 'Sell contract created successfully. Property ownership transferred to buyer.'
      });

    } catch (err) {
      await client.query('ROLLBACK');
      console.error("Transaction error:", err);
      throw err;
    } finally {
      client.release();
    }
  } catch (error) {
    console.error('Error creating sell contract:', error);
    return res.status(500).json({ 
      error: 'Internal server error',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Helpers function to create temporary user
const createTempUser = async (client, walletAddress) => {
  console.log("Creating temporary user with wallet:", walletAddress);
  
  const shortWallet = walletAddress.substring(0, 4);
  const timestamp = Date.now().toString().slice(-6);
  
  // Create temporary values
  const tempUsername = `tmp_${shortWallet}_${timestamp}`;
  const tempPassword = await bcrypt.hash(walletAddress, 10);
  const tempNationalId = `TMP${timestamp}${shortWallet}`.slice(0, 14);
  const tempEmail = `noreply_${shortWallet}_${timestamp}@example.com`;
  const tempPhone = `+1${timestamp}${shortWallet}`.slice(0, 15);

  // First check if user exists
  const userExistsResult = await client.query(
    'SELECT user_id FROM mobile_app_users WHERE wallet_address = $1',
    [walletAddress]
  );

  if (userExistsResult.rows.length === 0) {
    console.log("User doesn't exist. Creating new user with values:", {
      username: tempUsername,
      wallet: walletAddress
    });
    
    // Insert user with all required fields
    const insertResult = await client.query(
      `INSERT INTO mobile_app_users (
        username, 
        password_hash, 
        wallet_address, 
        national_id,
        email,
        phone_number
      ) VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING user_id`,
      [tempUsername, tempPassword, walletAddress, tempNationalId, tempEmail, tempPhone]
    );
    
    console.log("User created with ID:", insertResult.rows[0]?.user_id);
    return insertResult.rows[0]?.user_id;
  } else {
    console.log("User already exists with ID:", userExistsResult.rows[0].user_id);
    return userExistsResult.rows[0].user_id;
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
    // Get wallet address from JWT token
    const userWalletAddress = req.user.wallet_address;
    
    if (!userWalletAddress) {
      console.log("User wallet address not found in token:", req.user);
      return res.status(400).json({ error: 'User wallet address not found in token' });
    }
    
    console.log("Fetching requests for wallet:", userWalletAddress);
    
    const query = `
      SELECT *
      FROM property_requests
      WHERE seller_wallet_address = $1 OR buyer_wallet_address = $1
      ORDER BY created_at DESC
    `;
    const result = await pool.query(query, [userWalletAddress]);
    
    console.log(`Found ${result.rows.length} requests for wallet ${userWalletAddress}`);
    
    return res.json({ 
      success: true,
      requests: result.rows,
      count: result.rows.length
    });
  } catch (error) {
    console.error('Error fetching user property requests:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

// Get property requests representing properties owned by the logged-in user
exports.getOwnedProperties = async (req, res) => {
  try {
    // Get wallet address from JWT token
    const userWalletAddress = req.user.wallet_address;
    
    if (!userWalletAddress) {
      console.log("User wallet address not found in token:", req.user);
      return res.status(400).json({ error: 'User wallet address not found in token' });
    }
    
    console.log("Fetching owned properties for wallet:", userWalletAddress);

    // Modified query to select ONLY the requested fields
    const query = `
      SELECT 
        property_type,
        property_address,
        full_description,
        property_price,
        transaction_date
      FROM property_requests pr
      WHERE (
        (buyer_wallet_address = $1 AND status = 'approved')
        
      )
      ORDER BY transaction_date DESC;
    `;

    const result = await pool.query(query, [userWalletAddress]);
    
    console.log(`Found ${result.rows.length} properties for wallet ${userWalletAddress}`);
    
    // Format property prices as numbers
    const properties = result.rows.map(property => ({
      ...property,
      property_price: parseFloat(property.property_price) // Fix: Was using property_price variable instead of property.property_price
    }));

    return res.json({
      success: true,
      properties: properties,
      summary: {
        total: properties.length
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
