const mongoose = require('mongoose');

const bidSchema = mongoose.Schema({
    vehicleId: {
        type: String,
        required: [true, 'Please provide vehicle ID']
    },
    bidderPhoneNumber: {
        type: String,
        required: [true, 'Please provide bidder phone number']
    },
    bidAmount: {
        type: Number,
        required: [true, 'Please provide bid amount']
    },
    referenceId: {
        type: String,
        unique: true
    },
    status: {
        type: String,
        enum: ['highest', 'outbid'],
        default: 'highest'
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('Bid', bidSchema);
