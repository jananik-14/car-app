const mongoose = require('mongoose');

const otpSchema = mongoose.Schema({
    phoneNumber: {
        type: String,
        required: [true, 'Please add a phone number'],
    },
    otp: {
        type: String,
        required: [true, 'Please add the OTP'],
        length: [4, 'OTP must be 4 digits']
    },
    createdAt: {
        type: Date,
        default: Date.now,
        expires: 300 // The document will be automatically deleted after 5 minutes (300 seconds)
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('OTP', otpSchema);
