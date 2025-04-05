const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/authMiddleware');
const upload = require('../middleware/upload');

// Controllers
const propertyRequestController = require('../controllers/propertyRequestController');
const authController = require('../controllers/authController');
const managerController = require('../controllers/managerController');
const employeeController = require('../controllers/employeeController');
const adminController = require('../controllers/adminController');
const userController = require('../controllers/userController'); // Add this line

// Auth routes
router.post('/auth/signup', authController.signup);
router.post('/auth/login', authController.login);
router.post('/auth/logout', authMiddleware, authController.logout);

// Property request routes
router.post('/property-requests', 
  authMiddleware,
  upload.single('ownership_document'),
  propertyRequestController.createRequest
);

router.get('/property-requests',
  authMiddleware,
  propertyRequestController.getAllRequests
);

router.get('/property-requests/owned',
  authMiddleware,
  propertyRequestController.getOwnedProperties
);

router.get('/property-requests/my',
  authMiddleware,
  propertyRequestController.getUserRequests
);

router.patch('/property-requests/:id', 
  authMiddleware,
  propertyRequestController.updateRequestStatus  // This line was causing the error
);

// Add this with your other routes
router.get('/users/check-wallet/:address', userController.checkWalletExists);

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

module.exports = router;
