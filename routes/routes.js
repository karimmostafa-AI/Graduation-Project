const express = require('express');
const router = express.Router();

// Import controllers
const authController = require('../controllers/authController');
const propertyRequestController = require('../controllers/propertyRequestController');
const managerController = require('../controllers/managerController');
const employeeController = require('../controllers/employeeController');
const adminController = require('../controllers/adminController');
const notificationController = require('../controllers/notificationController');

// Import middleware
const authMiddleware = require('../middleware/authMiddleware');
const upload = require('../middleware/upload');

// Auth routes
router.post('/auth/signup', authController.signup);//done
router.post('/auth/login', authController.login);//done
router.post('/auth/logout', authMiddleware, authController.logout);//done
router.get('/auth/wallet', authMiddleware, authController.getWalletAddress);//new endpoint

// Protected admin routes
router.get('/admin/stats', authMiddleware.requireRole('admin'), adminController.getStats);

// Protected manager routes with multiple roles
router.get('/managers', 
  authMiddleware.requireRoles(['admin', 'manager']), 
  managerController.getManagers
);
router.post('/managers', 
  authMiddleware.requireRoles(['admin', 'manager']), 
  managerController.addManager
);
router.delete('/managers/:id', 
  authMiddleware.requireRoles(['admin', 'manager']), 
  managerController.requestManagerRemoval
);

// Protected employee routes
router.get('/employees', authMiddleware.requireRole('admin'), employeeController.getEmployees);
router.post('/employees', authMiddleware.requireRole('admin'), employeeController.addEmployee);
router.delete('/employees/:id', authMiddleware.requireRole('admin'), employeeController.removeEmployee);

// Property request routes
router.post('/property-requests', 
  authMiddleware, 
  upload.single('ownership_document'),
  propertyRequestController.createRequest
);//done
router.get('/property-requests/owned', authMiddleware, propertyRequestController.getOwnedProperties);// get all user's properties
router.get('/property-requests/requsits_history', authMiddleware, propertyRequestController.getUserRequests);// user all requests
router.get('/property-requests', authMiddleware, propertyRequestController.getAllRequests);// for the web
router.patch('/property-requests/:id', authMiddleware, propertyRequestController.updateRequestStatus);

// Notification routes - keep existing routes for backward compatibility
router.get('/notifications', 
  authMiddleware, 
  notificationController.getUserNotifications
);

router.patch('/notifications/:id/read', 
  authMiddleware, 
  notificationController.markAsRead
);

// Add new frontend-compatible notification routes
router.get('/user/notifications', 
  authMiddleware, 
  notificationController.getUserNotifications
);

router.get('/user/notifications/count', 
  authMiddleware, 
  notificationController.getNotificationsCount
);

// Add this new route for marking notifications as read
router.patch('/user/notifications/:id/read', 
  authMiddleware, 
  notificationController.markAsRead
);

// Add a debug endpoint for notifications
router.get('/debug/notifications', 
  authMiddleware,
  async (req, res) => {
    try {
      const userWalletAddress = req.user.wallet_address;
      const query = `SELECT notification_id FROM notifications WHERE user_wallet_address = $1 ORDER BY created_at DESC`;
      const result = await pool.query(query, [userWalletAddress]);
      
      res.json({
        success: true,
        user_wallet: userWalletAddress,
        notification_ids: result.rows.map(row => row.notification_id),
        count: result.rows.length
      });
    } catch (error) {
      console.error('Debug endpoint error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }
);

module.exports = router;
