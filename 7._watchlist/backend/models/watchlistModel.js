const mongoose = require('mongoose');

const watchlistSchema = mongoose.Schema({
    phoneNumber: {
        type: String,
        required: [true, 'Please add a user phone number']
    },
    vehicleId: {
        type: mongoose.Schema.Types.ObjectId,
        required: [true, 'Please add a vehicle ID']
    }
}, {
    timestamps: true
});

// Ensure a user can only add a specific vehicle once
watchlistSchema.index({ phoneNumber: 1, vehicleId: 1 }, { unique: true });

module.exports = mongoose.model('Watchlist', watchlistSchema);
