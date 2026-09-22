const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const notificationRoutes = require('./routes/notificationRoutes');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

app.use('/api/notification', notificationRoutes);

const PORT = process.env.PORT || 5004;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/wheels2drive_notifications';

mongoose.connect(MONGO_URI)
    .then(() => {
        console.log('Connected to MongoDB - Notifications');
        app.listen(PORT, () => {
            console.log(`Notifications Service running on port ${PORT}`);
        });
    })
    .catch(err => {
        console.error('Database connection error:', err);
    });
