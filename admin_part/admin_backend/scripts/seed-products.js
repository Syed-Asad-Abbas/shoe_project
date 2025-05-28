require('dotenv').config();
const mongoose = require('mongoose');
const Product = require('../../../shared_backend/models/Product');

const products = [
  {
    name: "Nike Air Max 270",
    description: "The Nike Air Max 270 delivers unrivaled comfort with its large window and fresh design.",
    price: 150.00,
    imageUrl: "https://example.com/images/nike_air_max.jpg",
    category: "Running",
    stockQuantity: 45,
    sizes: [7, 8, 9, 10, 11],
    colors: ["Black", "White", "Red"],
    featured: true
  },
  {
    name: "Adidas Ultraboost",
    description: "Ultraboost with Primeknit upper that adapts to the shape of your foot for adaptive support and comfort.",
    price: 180.00,
    imageUrl: "https://example.com/images/adidas_ultraboost.jpg",
    category: "Running",
    stockQuantity: 30,
    sizes: [8, 9, 10, 11, 12],
    colors: ["Black", "White", "Blue"],
    featured: true
  },
  {
    name: "Jordan Retro 1",
    description: "The Air Jordan 1 Retro High offers heritage style that transcends sport and culture.",
    price: 170.00,
    imageUrl: "https://example.com/images/jordan_retro.jpg",
    category: "Basketball",
    stockQuantity: 25,
    sizes: [8, 9, 10, 11],
    colors: ["Red", "Black", "White"],
    featured: true
  },
  {
    name: "Puma RS-X",
    description: "The Puma RS-X features bold, chunky design with RS technology for superior cushioning.",
    price: 120.00,
    imageUrl: "https://example.com/images/puma_rsx.jpg",
    category: "Casual",
    stockQuantity: 40,
    sizes: [7, 8, 9, 10, 11],
    colors: ["White", "Blue", "Yellow"],
    featured: false
  },
  {
    name: "New Balance 990",
    description: "The New Balance 990 delivers excellent cushioning and stability with premium materials.",
    price: 175.00,
    imageUrl: "https://example.com/images/new_balance_990.jpg",
    category: "Running",
    stockQuantity: 20,
    sizes: [8, 9, 10, 11],
    colors: ["Gray", "Navy", "Black"],
    featured: false
  }
];

const seedProducts = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Clear existing products
    await Product.deleteMany({});
    console.log('Cleared existing products');

    // Insert new products
    await Product.insertMany(products);
    console.log('Successfully seeded products');

    process.exit(0);
  } catch (error) {
    console.error('Error seeding products:', error);
    process.exit(1);
  }
};

seedProducts(); 