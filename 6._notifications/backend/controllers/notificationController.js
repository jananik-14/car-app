const Notification = require('../models/Notification');

exports.getNotifications = async (req, res) => {
    try {
        const { phoneNumber } = req.params;
        const notifications = await Notification.find({ phoneNumber }).sort({ createdAt: -1 });
        
        res.status(200).json({ success: true, data: notifications });
    } catch (error) {
        console.error('Error fetching notifications:', error);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};

exports.createNotification = async (req, res) => {
    try {
        const { phoneNumber, title, message } = req.body;
        
        if (!phoneNumber || !title || !message) {
            return res.status(400).json({ success: false, message: 'Missing required fields' });
        }

        const newNotification = new Notification({
            phoneNumber,
            title,
            message
        });

        await newNotification.save();

        res.status(201).json({ success: true, message: 'Notification created', data: newNotification });
    } catch (error) {
        console.error('Error creating notification:', error);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};

exports.markAsRead = async (req, res) => {
    try {
        const { id } = req.params;
        const notification = await Notification.findByIdAndUpdate(id, { isRead: true }, { new: true });
        
        if (!notification) {
            return res.status(404).json({ success: false, message: 'Notification not found' });
        }
        
        res.status(200).json({ success: true, message: 'Marked as read', data: notification });
    } catch (error) {
        console.error('Error marking notification as read:', error);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};
