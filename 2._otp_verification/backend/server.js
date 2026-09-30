const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const connectDB = require('./config/db');
const authRoutes = require('./routes/authRoutes');
const adminRoutes = require('./routes/adminRoutes');
const activityRoutes = require('./routes/activityRoutes');

// Load env vars
dotenv.config();

// Connect to database
connectDB();

const app = express();

// Enable CORS with preflight handling
app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'x-internal-key']
}));

// Body parser
app.use(express.json());

// Mount routers
app.use('/api/auth', authRoutes);
app.use('/api/user', authRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/activity', activityRoutes);

const PORT = process.env.PORT || 5000;

app.listen(PORT, console.log(`Server running on port ${PORT}`));
