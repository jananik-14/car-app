const mongoose = require('mongoose');

const vehicleSchema = mongoose.Schema({
    ownerPhoneNumber: {
        type: String,
        required: [true, 'Please add owner phone number']
    },
    make: {
        type: String
    },
    model: {
        type: String
    },
    year: {
        type: Number
    },
    km: {
        type: Number
    },
    engineNo: {
        type: String
    },
    numberPlate: {
        type: String,
        required: [true, 'Please add vehicle number plate']
    },
    chassisNo: {
        type: String,
        required: [true, 'Please add chassis number']
    },
    emdAmount: {
        type: Number
    },
    fineAmount: {
        type: Number
    },
    features: {
        type: [String],
        default: []
    },
    inspectionReport: {
        type: String
    },
    state: {
        type: String
    },
    fuelType: {
        type: String
    },
    transmission: {
        type: String
    },
    rtoCode: {
        type: String
    },
    status: {
        type: String,
        enum: ['pending', 'approved', 'rejected', 'live'],
        default: 'pending'
    },
    maxBidders: {
        type: Number,
        default: 10
    },
    biddingEnabled: {
        type: Boolean,
        default: false
    },
    currentHighestBid: {
        type: Number,
        default: 0
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('Vehicle', vehicleSchema);
