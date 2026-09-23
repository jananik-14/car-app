const mongoose = require('mongoose');

const vehicleSchema = mongoose.Schema({
    ownerPhoneNumber: {
        type: String,
        required: [true, 'Please add owner phone number']
    },
    // Step 1: Category
    vehicleType: {
        type: String, // e.g., 'Car / SUV'
    },
    fuelType: {
        type: String, // e.g., 'Petrol'
    },
    transmission: {
        type: String, // e.g., 'Manual'
    },
    // Step 2: Identity
    registrationNumber: {
        type: String, // from numberPlate
        required: [true, 'Please add vehicle registration number']
    },
    // Auto-fetched details (mocked or real from Vahan)
    make: { type: String },
    model: { type: String },
    year: { type: Number },
    rtoCode: { type: String },
    state: { type: String },
    chassisNo: { type: String },
    engineNo: { type: String },

    // Step 3: Health & Records
    kmDriven: {
        type: Number
    },
    ownerCount: {
        type: String, // e.g., '1st Owner'
    },
    insuranceType: {
        type: String,
    },
    insuranceExpiryDate: {
        type: Date,
    },

    // Step 4: Images (Arrays of URLs)
    frontViewImages: [String],
    rearViewImages: [String],
    leftRightImages: [String],
    interiorDashImages: [String],
    engineTyresImages: [String],
    rcInsuranceImages: [String],

    // Step 5: Pricing & Auction
    basePrice: {
        type: Number,
    },
    enableReservePrice: {
        type: Boolean,
        default: false
    },
    auctionDuration: {
        type: String, // e.g., '48 Hours'
    },

    // Administrative & Bidding fields
    status: {
        type: String,
        enum: ['pending', 'approved', 'rejected', 'live'],
        default: 'pending'
    },
    emdAmount: {
        type: Number,
        default: 0
    },
    fineAmount: {
        type: Number,
        default: 0
    },
    biddingEnabled: {
        type: Boolean,
        default: false
    },
    currentHighestBid: {
        type: Number,
        default: 0
    },
    maxBidders: {
        type: Number,
        default: 10
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('Vehicle', vehicleSchema);
