const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const connectDB = require('./config/db');
const watchlistRoutes = require('./routes/watchlistRoutes');

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
app.use('/api/watchlist', watchlistRoutes);

const PORT = process.env.PORT || 5005;

app.listen(PORT, () => {
    console.log(`Watchlist Server running on port ${PORT}`);
});