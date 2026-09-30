const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const subscriptionRoutes = require('./routes/subscriptionRoutes');
require('dotenv').config();

const app = express();
// Enable CORS with preflight handling
app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());

app.use('/api/subscription', subscriptionRoutes);

const PORT = process.env.PORT || 5003;
const mongoUri = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/wheels2drive_subscriptions_db';

app.listen(PORT, () => {
    console.log(`Subscriptions Service running on port ${PORT}`);
});

mongoose.connect(mongoUri)
    .then(() => {
        console.log('Connected to MongoDB - Subscriptions');
    })
    .catch(err => {
        console.error('Database connection error in Subscriptions:', err.message);
    });
