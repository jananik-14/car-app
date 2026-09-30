const mongoose = require('mongoose');

const connectDB = async () => {
    const mongoUri = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/wheels2drive_otp_db';
    try {
        const conn = await mongoose.connect(mongoUri, { serverSelectionTimeoutMS: 5000 });
        console.log(`MongoDB Connected: ${conn.connection.host}`);
    } catch (err) {
        console.error(`Atlas MongoDB connection failed (${err.message}). Attempting local fallback...`);
        try {
            const localUri = 'mongodb://127.0.0.1:27017/wheels2drive_otp_db';
            const conn = await mongoose.connect(localUri);
            console.log(`Connected to local MongoDB: ${conn.connection.host}`);
        } catch (localErr) {
            console.error(`Local MongoDB fallback failed: ${localErr.message}. Server will remain online.`);
        }
    }
};

module.exports = connectDB;