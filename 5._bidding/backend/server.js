const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const connectDB = require('./config/db');
const bidRoutes = require('./routes/bidRoutes');

// Load env vars
dotenv.config();

// Connect to database
connectDB();

const app = express();

// Body parser
app.use(express.json());

// Enable CORS
app.use(cors());

// Mount routers
app.use('/api/bid', bidRoutes);

const PORT = process.env.PORT || 5002;

app.listen(PORT, console.log(`Server running on port ${PORT}`));
