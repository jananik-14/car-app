const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const watchlistRoutes = require('./routes/watchlistRoutes');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

app.use('/api/watchlist', watchlistRoutes);

const PORT = process.env.PORT || 5005;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/wheels2drive_watchlist';

mongoose.connect(MONGO_URI, { useNewUrlParser: true, useUnifiedTopology: true })
    .then(() => {
        console.log('Connected to MongoDB - Watchlist');
        app.listen(PORT, () => {
            console.log(`Watchlist Service running on port ${PORT}`);
        });
    })
    .catch(err => {
        console.error('Database connection error:', err);
    });
