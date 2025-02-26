const express = require('express');
const router = express.Router();

// Import controllers
const authController = require('../controllers/authController');
const propertyRequestController = require('../controllers/propertyRequestController');
const managerController = require('../controllers/managerController');
const employeeController = require('../controllers/employeeController');
const adminController = require('../controllers/adminController');

// Import middleware
const authMiddleware = require('../middleware/authMiddleware');
const upload = require('../middleware/upload');

// Auth routes
router.post('/auth/signup', authController.signup);//done
router.post('/auth/login', authController.login);//done
router.post('/auth/logout', authMiddleware, authController.logout);//done

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
);
router.get('/property-requests/owned', authMiddleware, propertyRequestController.getOwnedProperties);// get all user's properties
router.get('/property-requests/requsits_history', authMiddleware, propertyRequestController.getUserRequests);// user all requests
router.get('/property-requests', authMiddleware, propertyRequestController.getAllRequests);// for the web
router.patch('/property-requests/:id', authMiddleware, propertyRequestController.updateRequestStatus);

module.exports = router;
