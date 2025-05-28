require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const connectDB = require('../../shared_backend/config/database');
const errorHandler = require('../../shared_backend/middleware/errorHandler');
const adminRoutes = require('./routes/adminRoutes');

const app = express();
const PORT = process.env.ADMIN_PORT || 3001;

// Connect to MongoDB
connectDB();

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Routes
app.use('/api/admin', adminRoutes);

// Error handling
app.use(errorHandler);

// Start server
app.listen(PORT, () => {
  console.log(`Admin server running on port ${PORT}`);
}); 