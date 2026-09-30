const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const connectDB = require('./config/db');
const vehicleRoutes = require('./routes/vehicleRoutes');
const uploadRoutes = require('./routes/uploadRoutes');
const path = require('path');
// Load env vars
dotenv.config();

// Connect to database
connectDB();

const app = express();

// Enable CORS with preflight handling
app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));

// Body parser
app.use(express.json());

// Mount routers
app.use('/api/vehicle/upload', uploadRoutes);
app.use('/api/vehicle', vehicleRoutes);

// Make uploads folder static
app.use('/uploads', express.static(path.join(__dirname, '/uploads')));
const PORT = process.env.PORT || 5001;

app.listen(PORT, console.log(`Server running on port ${PORT}`));
