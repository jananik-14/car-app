const Notification = require('../models/notificationModel');

// @desc    Get all notifications for a user
// @route   GET /api/notifications
// @access  Private
const getNotifications = async (req, res) => {
    try {
        const notifications = await Notification.find({ recipientPhoneNumber: req.user.phoneNumber }).sort({ createdAt: -1 });

        res.status(200).json({
            success: true,
            data: notifications
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};

// @desc    Create a new notification
// @route   POST /api/notifications/create
// @access  Public (In a real app, protect this so only internal services can call it)
const createNotification = async (req, res) => {
    try {
        const { recipientPhoneNumber, title, body, type } = req.body;

        if (!recipientPhoneNumber || !title || !body) {
            return res.status(400).json({ success: false, message: 'Please provide recipientPhoneNumber, title, and body' });
        }

        const notification = await Notification.create({
            recipientPhoneNumber,
            title,
            body,
            type: type || 'info'
        });

        res.status(201).json({
            success: true,
            data: notification
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};

module.exports = {
    getNotifications,
    createNotification
};
