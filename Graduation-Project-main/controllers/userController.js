const pool = require('../db');

exports.checkWalletExists = async (req, res) => {
  try {
    const { address } = req.params;
    console.log('Checking wallet:', address);

    const result = await pool.query(
      'SELECT EXISTS(SELECT 1 FROM mobile_app_users WHERE wallet_address = $1)',
      [address]
    );

    res.json({ exists: result.rows[0].exists });
  } catch (error) {
    console.error('Error checking wallet:', error);
    res.status(500).json({ error: 'Failed to check wallet address' });
  }
};
