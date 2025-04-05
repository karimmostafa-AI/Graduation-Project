const pool = require('../db');
const path = require('path');
const fs = require('fs');
const { ethers } = require('ethers');
const config = require('../config');
const GovernmentPropertyVerification = require('../artifacts/contracts/GovernmentPropertyVerification.sol/GovernmentPropertyVerification.json');

// Helper function to generate unique property ID
const generatePropertyId = () => {
  const timestamp = Date.now().toString(36);
  const randomStr = Math.random().toString(36).substring(2, 6);
  const propertyId = (timestamp + randomStr).toUpperCase().padEnd(16, '0');
  return propertyId.substring(0, 16);
};

exports.createRequest = async (req, res) => {
  let uploadedFile = null;

  try {
    const { seller_wallet_address, buyer_wallet_address, full_description, property_price } = req.body;

    // Clean wallet addresses first
    const cleanSellerAddress = seller_wallet_address.trim();
    const cleanBuyerAddress = buyer_wallet_address.trim();

    // Verify both wallet addresses exist in mobile_app_users
    const usersCheck = await pool.query(
      'SELECT wallet_address FROM mobile_app_users WHERE wallet_address = $1 OR wallet_address = $2',
      [cleanSellerAddress, cleanBuyerAddress]
    );

    const existingWallets = new Set(usersCheck.rows.map(row => row.wallet_address));

    if (!existingWallets.has(cleanSellerAddress)) {
      throw new Error(`Seller wallet address ${cleanSellerAddress} is not registered`);
    }

    if (!existingWallets.has(cleanBuyerAddress)) {
      throw new Error(`Buyer wallet address ${cleanBuyerAddress} is not registered`);
    }

    // Rest of validation
    if (!full_description || !property_price) {
      throw new Error('All fields are required');
    }

    // File validation
    if (!req.file) {
      throw new Error('Ownership document is required');
    }
    uploadedFile = req.file;

    // Price validation
    const numericPrice = parseFloat(property_price);
    if (isNaN(numericPrice) || numericPrice <= 0) {
      throw new Error('Invalid price value');
    }

    // Database insert with cleaned addresses
    const result = await pool.query(`
      INSERT INTO property_requests (
        property_id,
        seller_wallet_address,
        buyer_wallet_address,
        full_description,
        property_price,
        ownership_document,
        status,
        created_at,
        updated_at
      ) VALUES ($1, $2, $3, $4, $5, $6, 'pending', NOW(), NOW())
      RETURNING *
    `, [
      generatePropertyId(),
      cleanSellerAddress,
      cleanBuyerAddress,
      full_description.trim(),
      numericPrice,
      uploadedFile.filename
    ]);

    console.log('Created request:', result.rows[0]);

    res.status(201).json({
      success: true,
      message: 'Property request created successfully',
      request: result.rows[0]
    });

  } catch (error) {
    console.error('Creation error:', {
      message: error.message,
      code: error.code,
      detail: error.detail
    });

    // Cleanup on error
    if (uploadedFile?.path) {
      fs.unlink(uploadedFile.path, () => {});
    }

    res.status(400).json({
      error: error.message || 'Failed to create property request'
    });
  }
};

exports.getAllRequests = async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM property_requests ORDER BY created_at DESC'
    );
    res.json({ requests: result.rows });
  } catch (error) {
    console.error('Error fetching properties:', error);
    res.status(500).json({ error: 'Failed to fetch properties' });
  }
};

exports.getUserRequests = async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM property_requests WHERE seller_wallet_address = $1 OR buyer_wallet_address = $1 ORDER BY created_at DESC',
      [req.user.wallet_address]
    );
    res.json({ requests: result.rows });
  } catch (error) {
    console.error('Error fetching user properties:', error);
    res.status(500).json({ error: 'Failed to fetch properties' });
  }
};

exports.getOwnedProperties = async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM property_requests WHERE buyer_wallet_address = $1 AND status = \'approved\' ORDER BY created_at DESC',
      [req.user.wallet_address]
    );
    res.json({ properties: result.rows });
  } catch (error) {
    console.error('Error fetching owned properties:', error);
    res.status(500).json({ error: 'Failed to fetch properties' });
  }
};

exports.updateRequestStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    console.log('Updating request status:', { id, status });

    // First update database
    const result = await pool.query(`
      UPDATE property_requests 
      SET status = $1, updated_at = NOW() 
      WHERE request_id = $2 
      RETURNING *
    `, [status, id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Property request not found' });
    }

    const request = result.rows[0];
    console.log('Updated request:', request);

    // If approved, create blockchain transaction
    if (status === 'approved') {
      try {
        const provider = new ethers.JsonRpcProvider(config.network.rpcUrl);
        const privateKey = process.env.ADMIN_PRIVATE_KEY;
        const wallet = new ethers.Wallet(privateKey, provider);
        
        const contract = new ethers.Contract(
          config.contractAddress,
          GovernmentPropertyVerification.abi,
          wallet
        );

        // Create token URI (you might want to customize this)
        const tokenURI = `ipfs://property/${request.property_id}`;

        // Create property token on blockchain
        const tx = await contract.createPropertyToken(
          tokenURI,
          ethers.parseEther(request.property_price.toString()),
          request.buyer_wallet_address,
          request.full_description
        );

        console.log('Blockchain transaction initiated:', tx.hash);

        // Wait for transaction confirmation
        const receipt = await tx.wait();
        console.log('Transaction confirmed:', receipt);

        // Update database with transaction hash
        await pool.query(`
          UPDATE property_requests 
          SET transaction_hash = $1 
          WHERE request_id = $2
        `, [tx.hash, id]);
      } catch (blockchainError) {
        console.error('Blockchain interaction failed:', blockchainError);
        // Don't fail the request, just log the blockchain error
      }
    }

    res.json({
      success: true,
      message: `Property request ${status} successfully`,
      request: result.rows[0]
    });

  } catch (error) {
    console.error('Error updating request status:', error);
    res.status(500).json({
      error: 'Failed to update request status',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};
