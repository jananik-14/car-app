const mongoose = require('mongoose');

const userProfileSchema = mongoose.Schema({
    phoneNumber: {
        type: String,
        required: [true, 'Please add a phone number'],
        unique: true
    },
    role: {
        type: String,
        enum: ['client', 'admin'],
        default: 'client'
    },
    name: {
        type: String
    },
    email: {
        type: String
    },
    address: {
        type: String
    },
    city: {
        type: String
    },
    state: {
        type: String
    },
    pincode: {
        type: String
    },
    isProfileComplete: {
        type: Boolean,
        default: false
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('UserProfile', userProfileSchema);
