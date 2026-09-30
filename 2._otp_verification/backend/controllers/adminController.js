const User = require('../models/userModel');
const Activity = require('../models/activityModel');

// Helper to format user output without email
const formatUserOutput = (user) => ({
    id: user._id,
    name: user.name || 'N/A',
    phoneNumber: user.phoneNumber,
    status: user.status || 'verified',
    profileCompleted: user.profileCompleted || false,
    createdAt: user.createdAt,
    lastLoginAt: user.lastLoginAt,
    lastActiveAt: user.lastActiveAt
});

// Helper for search query on name or phoneNumber
const buildSearchFilter = (search) => {
    if (!search || !search.trim()) return {};
    const regex = new RegExp(search.trim(), 'i');
    return {
        $or: [
            { name: regex },
            { phoneNumber: regex }
        ]
    };
};

// @desc    Get all client users
// @route   GET /api/admin/clients
// @access  Private/Admin
const getClients = async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 10;
        const skip = (page - 1) * limit;

        const searchFilter = buildSearchFilter(req.query.search);
        const query = { role: 'user', ...searchFilter };

        const total = await User.countDocuments(query);
        const users = await User.find(query)
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limit);

        res.status(200).json({
            success: true,
            total,
            page,
            data: users.map(formatUserOutput)
        });
    } catch (error) {
        console.error('[ADMIN CLIENTS ERROR]', error);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};

// @desc    Get active logins (active within last 15 minutes)
// @route   GET /api/admin/active-logins
// @access  Private/Admin
const getActiveLogins = async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 10;
        const skip = (page - 1) * limit;

        const fifteenMinsAgo = new Date(Date.now() - 15 * 60 * 1000);
        const searchFilter = buildSearchFilter(req.query.search);
        const query = {
            role: 'user',
            lastActiveAt: { $gte: fifteenMinsAgo },
            ...searchFilter
        };

        const total = await User.countDocuments(query);
        const users = await User.find(query)
            .sort({ lastActiveAt: -1 })
            .skip(skip)
            .limit(limit);

        res.status(200).json({
            success: true,
            total,
            page,
            data: users.map(formatUserOutput)
        });
    } catch (error) {
        console.error('[ADMIN ACTIVE LOGINS ERROR]', error);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};

// @desc    Get users with profileCompleted = true
// @route   GET /api/admin/profile-completed
// @access  Private/Admin
const getProfileCompleted = async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 10;
        const skip = (page - 1) * limit;

        const searchFilter = buildSearchFilter(req.query.search);
        const query = {
            role: 'user',
            profileCompleted: true,
            ...searchFilter
        };

        const total = await User.countDocuments(query);
        const users = await User.find(query)
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limit);

        res.status(200).json({
            success: true,
            total,
            page,
            data: users.map(formatUserOutput)
        });
    } catch (error) {
        console.error('[ADMIN PROFILE COMPLETED ERROR]', error);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};

// @desc    Get activity history log
// @route   GET /api/admin/history
// @access  Private/Admin
const getActivityHistory = async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 10;
        const skip = (page - 1) * limit;

        const query = {};
        if (req.query.action) {
            query.action = req.query.action;
        }
        if (req.query.phoneNumber) {
            let phone = req.query.phoneNumber.trim();
            if (!phone.startsWith('+91')) {
                phone = `+91${phone.replace(/^0+/, '')}`;
            }
            query.phoneNumber = phone;
        }

        const total = await Activity.countDocuments(query);
        const activities = await Activity.find(query)
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limit);

        res.status(200).json({
            success: true,
            total,
            page,
            data: activities
        });
    } catch (error) {
        console.error('[ADMIN HISTORY ERROR]', error);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};

// @desc    Log activity (Internal Endpoint)
// @route   POST /api/activity/log
// @access  Internal (Protected by INTERNAL_API_KEY)
const logActivity = async (req, res) => {
    try {
        const apiKey = req.headers['x-internal-key'];
        const validKey = process.env.INTERNAL_API_KEY || 'internal_wheels2drive_secret_key_2026';

        if (!apiKey || apiKey !== validKey) {
            return res.status(401).json({ success: false, message: 'Unauthorized internal request' });
        }

        let { phoneNumber, action, details } = req.body;

        if (!phoneNumber || !action) {
            return res.status(400).json({ success: false, message: 'phoneNumber and action are required' });
        }

        // Format phone
        let cleaned = phoneNumber.toString().trim();
        if (!cleaned.startsWith('+91')) {
            cleaned = `+91${cleaned.replace(/^0+/, '')}`;
        }

        const activity = await Activity.create({
            phoneNumber: cleaned,
            action,
            details: details || {}
        });

        // Also update lastActiveAt for the user
        await User.findOneAndUpdate(
            { phoneNumber: cleaned },
            { lastActiveAt: new Date() }
        );

        console.log(`[ACTIVITY LOGGED] ${cleaned} -> ${action}`);

        res.status(201).json({ success: true, data: activity });
    } catch (error) {
        console.error('[LOG ACTIVITY ERROR]', error);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};

module.exports = {
    getClients,
    getActiveLogins,
    getProfileCompleted,
    getActivityHistory,
    logActivity
};
