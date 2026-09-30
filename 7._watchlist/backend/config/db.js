const mongoose = require('mongoose');

const connectDB = async () => {
    const mongoUri = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/wheels2drive_watchlist_db';
    try {
        const maskedUri = mongoUri.replace(/\/\/[^:]+:[^@]+@/, '//***:***@');
        console.log(`[Watchlist DB] Connecting to: ${maskedUri}`);
        const conn = await mongoose.connect(mongoUri);
        console.log(`[Watchlist DB] MongoDB Connected: ${conn.connection.host}`);
    } catch (err) {
        console.error(`[Watchlist DB] MongoDB Connection Error: ${err.message}`);
        try {
            const localUri = 'mongodb://127.0.0.1:27017/wheels2drive_watchlist_db';
            const conn = await mongoose.connect(localUri);
            console.log(`[Watchlist DB] Connected to local fallback: ${conn.connection.host}`);
        } catch (localErr) {
            console.error(`[Watchlist DB] Local fallback error: ${localErr.message}`);
        }
    }
};

module.exports = connectDB;
