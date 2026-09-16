const mongoose = require('mongoose');

const watchlistSchema = new mongoose.Schema({
    phoneNumber: { type: String, required: true },
    vehicleId: { type: String, required: true }, // Keeping as String to be compatible with other services
    addedAt: { type: Date, default: Date.now }
});

// Ensure a user can only add a specific vehicle once
watchlistSchema.index({ phoneNumber: 1, vehicleId: 1 }, { unique: true });

module.exports = mongoose.model('Watchlist', watchlistSchema);
