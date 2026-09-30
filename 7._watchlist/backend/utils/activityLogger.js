const axios = require('axios');

const logActivity = async (phoneNumber, action, details = {}) => {
    try {
        if (!phoneNumber) return;
        const internalKey = process.env.INTERNAL_API_KEY || 'internal_wheels2drive_secret_key_2026';
        const targetUrl = process.env.AUTH_SERVICE_URL || 'http://localhost:5000/api/activity/log';

        await axios.post(targetUrl, {
            phoneNumber,
            action,
            details
        }, {
            headers: {
                'x-internal-key': internalKey
            }
        });
    } catch (err) {
        console.error(`[ACTIVITY LOGGER ERROR] Failed to log ${action} for ${phoneNumber}:`, err.message);
    }
};

module.exports = { logActivity };
