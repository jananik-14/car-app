const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const connectDB = require('./config/db');
const userProfileRoutes = require('./routes/userProfileRoutes');

// Load env vars
dotenv.config();

// Connect to database
connectDB();

const app = express();

// Middleware
app.use(express.json());
app.use(cors());

// Mount routers
app.use('/api/profile', userProfileRoutes);

const PORT = process.env.PORT || 5006;

app.listen(PORT, () => {
    console.log(`User Profile Server running on port ${PORT}`);
});
