const pool = require('../db');

exports.getStats = async (req, res) => {
  try {
    const stats = {
      totalProperties: 0,
      pendingRequests: 0,
      approvedRequests: 0,
      totalUsers: 0
    };

    // Get property requests stats
    const requestsStats = await pool.query(`
      SELECT 
        COUNT(*) as total,
        COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending,
        COUNT(CASE WHEN status = 'approved' THEN 1 END) as approved
      FROM property_requests
    `);

    // Get users count
    const usersCount = await pool.query('SELECT COUNT(*) as total FROM mobile_app_users');

    stats.totalProperties = parseInt(requestsStats.rows[0].total);
    stats.pendingRequests = parseInt(requestsStats.rows[0].pending);
    stats.approvedRequests = parseInt(requestsStats.rows[0].approved);
    stats.totalUsers = parseInt(usersCount.rows[0].total);

    res.json({ success: true, stats });
  } catch (error) {
    console.error('Error fetching admin stats:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};
