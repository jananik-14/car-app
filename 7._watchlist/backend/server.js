const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const watchlistRoutes = require('./routes/watchlistRoutes');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use('/api/watchlist', watchlistRoutes);

// Port
const PORT = process.env.PORT || 5005;

// MongoDB Atlas connection
const MONGO_URI = process.env.MONGO_URI;

mongoose.connect(MONGO_URI)
    .then(() => {
        console.log('Connected to MongoDB - Watchlist');

        app.listen(PORT, () => {
            console.log(`Watchlist Service running on port ${PORT}`);
        });
    })
    .catch(err => {
        console.error('Database connection error:', err.message);
    });