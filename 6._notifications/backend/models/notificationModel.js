const mongoose = require('mongoose');

const notificationSchema = mongoose.Schema({
    recipientPhoneNumber: {
        type: String,
        required: [true, 'Please add a recipient phone number']
    },
    title: {
        type: String,
        required: [true, 'Please add a title']
    },
    body: {
        type: String,
        required: [true, 'Please add a body']
    },
    type: {
        type: String,
        enum: ['info', 'alert', 'success', 'warning'],
        default: 'info'
    },
    isRead: {
        type: Boolean,
        default: false
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('Notification', notificationSchema);
