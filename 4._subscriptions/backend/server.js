const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const subscriptionRoutes = require('./routes/subscriptionRoutes');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

app.use('/api/subscription', subscriptionRoutes);

const PORT = process.env.PORT || 5003;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/wheels2drive_subscriptions';

mongoose.connect(MONGO_URI)
    .then(() => {
        console.log('Connected to MongoDB - Subscriptions');
        app.listen(PORT, () => {
            console.log(`Subscriptions Service running on port ${PORT}`);
        });
    })
    .catch(err => {
        console.error('Database connection error:', err);
    });
