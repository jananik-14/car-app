const mongoose = require('mongoose');

const userSchema = mongoose.Schema({
    phoneNumber: {
        type: String,
        required: [true, 'Please add a phone number'],
        unique: true
    },
    name: {
        type: String,
        default: ''
    },
    email: {
        type: String,
        default: ''
    },
    role: {
        type: String,
        enum: ['user', 'admin'],
        default: 'user'
    },
    isVerified: {
        type: Boolean,
        default: true
    },
    termsAccepted: {
        type: Boolean,
        default: false
    },
    profileCompleted: {
        type: Boolean,
        default: false
    },
    status: {
        type: String,
        enum: ['verified', 'pending'],
        default: 'verified'
    },
    lastLoginAt: {
        type: Date,
        default: Date.now
    },
    lastActiveAt: {
        type: Date,
        default: Date.now
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('User', userSchema);
