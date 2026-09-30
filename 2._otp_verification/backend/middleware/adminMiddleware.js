const jwt = require('jsonwebtoken');
const User = require('../models/userModel');

const adminMiddleware = async (req, res, next) => {
    let token;

    if (
        req.headers.authorization &&
        req.headers.authorization.startsWith('Bearer')
    ) {
        try {
            token = req.headers.authorization.split(' ')[1];
            const decoded = jwt.verify(token, process.env.JWT_SECRET || 'secret_key_here');

            const user = await User.findOne({ phoneNumber: decoded.phoneNumber });

            if (!user) {
                return res.status(401).json({ success: false, message: 'User not found' });
            }

            if (user.role !== 'admin') {
                return res.status(403).json({ success: false, message: 'Access denied: Admin role required' });
            }

            req.user = user;
            next();
            return;
        } catch (error) {
            console.error('[ADMIN MIDDLEWARE ERROR]', error.message);
            return res.status(401).json({ success: false, message: 'Not authorized, token failed' });
        }
    }

    if (!token) {
        return res.status(401).json({ success: false, message: 'Not authorized, no token provided' });
    }
};

module.exports = { adminMiddleware };
