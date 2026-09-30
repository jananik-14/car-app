const mongoose = require('mongoose');

const activitySchema = mongoose.Schema({
    phoneNumber: {
        type: String,
        required: true
    },
    action: {
        type: String,
        required: true,
        enum: [
            'login',
            'post_vehicle',
            'bid',
            'subscribe',
            'watchlist_add',
            'watchlist_remove',
            'profile_update'
        ]
    },
    details: {
        type: Object,
        default: {}
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('Activity', activitySchema);
