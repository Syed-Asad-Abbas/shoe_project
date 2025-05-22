const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const connectDB = require('../../shared_backend/config/database');
const errorHandler = require('../../shared_backend/middleware/errorHandler');
const clientRoutes = require('./routes/clientRoutes');

const app = express();
const PORT = process.env.CLIENT_PORT || 3000;

// Connect to MongoDB
connectDB();

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Routes
app.use('/api', clientRoutes);

// Error handling
app.use(errorHandler);

// Start server
app.listen(PORT, () => {
  console.log(`Client server running on port ${PORT}`);
}); 