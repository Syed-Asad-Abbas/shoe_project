const mongoose = require('mongoose');

const productSchema = new mongoose.Schema({
  name: { 
    type: String, 
    required: true 
  },
  description: { 
    type: String, 
    required: true 
  },
  price: { 
    type: Number, 
    required: true 
  },
  imageUrl: { 
    type: String, 
    required: true 
  },
  discount: { 
    type: Number, 
    default: 0 
  },
  category: { 
    type: String, 
    required: true 
  },
  sizes: [{ 
    type: Number
  }],
  colors: [{ 
    type: String 
  }],
  inStock: { 
    type: Boolean, 
    default: true 
  },
  featured: { 
    type: Boolean, 
    default: false 
  },
  stockQuantity: { 
    type: Number, 
    default: 0 
  },
  rating: { 
    type: Number, 
    default: 0 
  },
  reviewCount: { 
    type: Number, 
    default: 0 
  }
}, { 
  timestamps: true 
});

module.exports = mongoose.model('Product', productSchema); 