const express = require('express');
const router = express.Router();
const authenticate = require('../../../shared_backend/middleware/authenticate');
const productController = require('../controllers/productController');
const orderController = require('../controllers/orderController');

// Product routes
router.get('/products', authenticate, productController.getAllProducts);
router.get('/products/:id', authenticate, productController.getProductById);
router.post('/products', authenticate, productController.createProduct);
router.put('/products/:id', authenticate, productController.updateProduct);
router.delete('/products/:id', authenticate, productController.deleteProduct);
router.get('/products/featured', authenticate, productController.getFeaturedProducts);
router.patch('/products/:id/stock', authenticate, productController.updateStock);

// Order routes
router.get('/orders', authenticate, orderController.getAllOrders);
router.get('/orders/:id', authenticate, orderController.getOrderById);
router.patch('/orders/:id/status', authenticate, orderController.updateOrderStatus);
router.get('/orders/status/:status', authenticate, orderController.getOrdersByStatus);
router.get('/orders/date-range', authenticate, orderController.getOrdersByDateRange);
router.get('/orders/statistics', authenticate, orderController.getOrderStatistics);

// Test route
router.get('/test', (req, res) => {
  res.json({ message: 'Admin API is working!' });
});

// Protected route example
router.get('/protected', authenticate, (req, res) => {
  res.json({ message: 'This is a protected route', user: req.user });
});

module.exports = router;
