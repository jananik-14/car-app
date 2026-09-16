const mongoose = require('mongoose');

const subscriptionSchema = new mongoose.Schema({
    phoneNumber: { type: String, required: true },
    planId: { type: String, required: true },
    status: { type: String, required: true, enum: ['active', 'expired', 'cancelled'], default: 'active' },
    startDate: { type: Date, required: true, default: Date.now },
    endDate: { type: Date, required: true }
});

module.exports = mongoose.model('Subscription', subscriptionSchema);
