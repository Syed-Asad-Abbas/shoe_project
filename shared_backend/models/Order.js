const mongoose = require('mongoose');

const orderSchema = new mongoose.Schema({
  customerName: {
    type: String,
    required: true
  },
  customerEmail: {
    type: String,
    required: true
  },
  orderDate: {
    type: Date,
    default: Date.now
  },
  status: {
    type: Number,
    default: 1, // 1: Processing, 2: Shipped, 3: Delivered, 4: Cancelled
    enum: [1, 2, 3, 4]
  },
  items: [{
    productId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Product',
      required: true
    },
    name: String,
    price: Number,
    quantity: Number,
    size: String,
    color: String
  }],
  subtotal: {
    type: Number,
    required: true
  },
  shippingCost: {
    type: Number,
    required: true
  },
  tax: {
    type: Number,
    required: true
  },
  totalAmount: {
    type: Number,
    required: true
  },
  shippingAddress: {
    type: String,
    required: true
  },
  paymentMethod: {
    type: String,
    required: true
  },
  trackingNumber: String,
  deliveryDate: Date
}, {
  timestamps: true
});

module.exports = mongoose.model('Order', orderSchema); 