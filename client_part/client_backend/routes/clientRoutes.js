const express = require('express');
const router = express.Router();
const authenticate = require('../../../shared_backend/middleware/authenticate');
const authController = require('../controllers/authController');
const cartController = require('../controllers/cartController');
const productController = require('../controllers/productController');

// Auth routes
router.post('/auth/register', authController.register);
router.post('/auth/login', authController.login);
router.get('/auth/profile', authenticate, authController.getProfile);
router.put('/auth/profile', authenticate, authController.updateProfile);

// Product routes (public)
router.get('/products', productController.getAllProducts);
router.get('/products/:id', productController.getProductById);
router.get('/products/featured', productController.getFeaturedProducts);
router.get('/products/category/:category', productController.getProductsByCategory);

// Cart routes
router.get('/cart', authenticate, cartController.getCart);
router.post('/cart/items', authenticate, cartController.addToCart);
router.put('/cart/items/:itemId', authenticate, cartController.updateCartItem);
router.delete('/cart/items/:itemId', authenticate, cartController.removeFromCart);
router.delete('/cart', authenticate, cartController.clearCart);

module.exports = router;
