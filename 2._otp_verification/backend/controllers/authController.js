const OTP = require('../models/otpModel');
const User = require('../models/userModel');
const Activity = require('../models/activityModel');
const jwt = require('jsonwebtoken');
const { sendSMS } = require('../utils/smsService');

const formatPhone = (phone) => {
    if (!phone) return '';
    let cleaned = phone.toString().trim();
    if (!cleaned.startsWith('+91')) {
        cleaned = `+91${cleaned.replace(/^0+/, '')}`;
    }
    return cleaned;
};

// @desc    Generate OTP (4-digit)
// @route   POST /api/auth/generate-otp
// @access  Public
const generateOTP = async (req, res) => {
    try {
        let { phoneNumber } = req.body;

        if (!phoneNumber) {
            return res.status(400).json({ success: false, message: 'Phone number is required' });
        }

        phoneNumber = formatPhone(phoneNumber);

        // Validate Indian phone number format: +91 followed by exactly 10 digits
        const phoneRegex = /^\+91\d{10}$/;
        if (!phoneRegex.test(phoneNumber)) {
            return res.status(400).json({ success: false, message: 'Invalid phone number format. Must be +91 followed by 10 digits' });
        }

        // Generate a 4-digit OTP
        const otp = Math.floor(1000 + Math.random() * 9000).toString();

        // Delete any existing OTP for this number
        await OTP.deleteMany({ phoneNumber });

        // Save new OTP
        const otpRecord = await OTP.create({
            phoneNumber,
            otp
        });

        // Send OTP via SMS
        await sendSMS(phoneNumber, `Your Wheels2Drive OTP is ${otp}. It is valid for 5 minutes.`);

        res.status(200).json({
            success: true,
            message: 'OTP generated successfully',
            data: {
                phoneNumber: otpRecord.phoneNumber,
                otp: otpRecord.otp, // Returned for dev/testing visibility
                expiresIn: '5 minutes'
            }
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};

// @desc    Verify OTP (4-digit)
// @route   POST /api/auth/verify-otp
// @access  Public
const verifyOTP = async (req, res) => {
    try {
        let { phoneNumber, otp } = req.body;

        if (!phoneNumber || otp === undefined || otp === null) {
            return res.status(400).json({ success: false, message: 'Phone number and OTP are required' });
        }

        phoneNumber = formatPhone(phoneNumber);
        const otpStr = String(otp).trim();

        if (otpStr.length !== 4) {
            return res.status(400).json({ success: false, message: 'OTP must be exactly 4 digits' });
        }

        // Find the OTP in database
        const otpRecord = await OTP.findOne({ phoneNumber });

        console.log(`----------------------------------------------------`);
        console.log(`[VERIFY OTP LOG] Received Phone: "${phoneNumber}", Received OTP: "${otpStr}"`);
        console.log(`[VERIFY OTP LOG] DB OTP Record: ${otpRecord ? `"${otpRecord.otp}"` : 'NOT FOUND IN DB'}`);
        console.log(`----------------------------------------------------`);

        // If test OTP '1234' or valid OTP match
        const isValidTestOtp = (otpStr === '1234');
        const isValidDbOtp = otpRecord && (String(otpRecord.otp).trim() === otpStr);

        if (!isValidTestOtp && !isValidDbOtp) {
            return res.status(400).json({ success: false, message: 'Invalid or expired OTP' });
        }

        // Clean up OTP from database if present
        if (otpRecord) {
            await OTP.deleteOne({ _id: otpRecord._id });
        }

        // Determine role (9999999999 or specified admin numbers get 'admin' role)
        const isAdminNum = phoneNumber.includes('9999999999');
        const assignedRole = isAdminNum ? 'admin' : 'user';

        const now = new Date();

        // Create or update the user
        let user = await User.findOne({ phoneNumber });
        if (!user) {
            user = await User.create({
                phoneNumber,
                isVerified: true,
                role: assignedRole,
                status: 'verified',
                lastLoginAt: now,
                lastActiveAt: now
            });
        } else {
            user.isVerified = true;
            if (isAdminNum) user.role = 'admin';
            user.lastLoginAt = now;
            user.lastActiveAt = now;
            await user.save();
        }

        // Log login activity
        try {
            await Activity.create({
                phoneNumber: user.phoneNumber,
                action: 'login',
                details: { role: user.role }
            });
        } catch (actErr) {
            console.error('[ACTIVITY LOG ERROR]', actErr.message);
        }

        // Generate JWT token
        const token = jwt.sign(
            { phoneNumber: user.phoneNumber, id: user._id, role: user.role },
            process.env.JWT_SECRET || 'secret_key_here',
            { expiresIn: '30d' }
        );

        res.status(200).json({
            success: true,
            message: 'OTP verified successfully',
            data: {
                token,
                user: { 
                    id: user._id,
                    phoneNumber: user.phoneNumber,
                    name: user.name,
                    email: user.email,
                    role: user.role,
                    isVerified: user.isVerified,
                    termsAccepted: user.termsAccepted,
                    profileCompleted: user.profileCompleted,
                    status: user.status,
                    lastLoginAt: user.lastLoginAt,
                    lastActiveAt: user.lastActiveAt
                }
            }
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};

// @desc    Update User Profile (STEP 3)
// @route   POST /api/user/profile or /api/auth/profile
// @access  Private
const updateProfile = async (req, res) => {
    try {
        const { name, email } = req.body;
        const phoneNumber = req.user.phoneNumber;

        let user = await User.findOne({ phoneNumber });
        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        if (name !== undefined) user.name = name.trim();
        if (email !== undefined) user.email = email.trim();

        // Set profileCompleted = true when name and email are filled
        if (user.name && user.email) {
            user.profileCompleted = true;
        }

        user.lastActiveAt = new Date();
        await user.save();

        res.status(200).json({
            success: true,
            message: 'Profile updated successfully',
            data: {
                id: user._id,
                phoneNumber: user.phoneNumber,
                name: user.name,
                email: user.email,
                role: user.role,
                profileCompleted: user.profileCompleted,
                status: user.status,
                lastLoginAt: user.lastLoginAt,
                lastActiveAt: user.lastActiveAt
            }
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};

// @desc    Accept Terms of Use
// @route   POST /api/auth/accept-terms
// @access  Public
const acceptTerms = async (req, res) => {
    try {
        const { phoneNumber, termsAccepted } = req.body;

        if (!phoneNumber) {
            return res.status(400).json({ success: false, message: 'Phone number is required' });
        }

        if (termsAccepted !== true) {
            return res.status(400).json({ success: false, message: 'You must accept the terms to continue' });
        }

        const user = await User.findOne({ phoneNumber });

        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found. Please verify OTP first.' });
        }

        user.termsAccepted = true;
        user.lastActiveAt = new Date();
        await user.save();

        res.status(200).json({
            success: true,
            message: 'Terms of use accepted successfully',
            data: {
                user: {
                    phoneNumber: user.phoneNumber,
                    isVerified: user.isVerified,
                    termsAccepted: user.termsAccepted,
                    role: user.role
                }
            }
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};

module.exports = {
    generateOTP,
    verifyOTP,
    updateProfile,
    acceptTerms
};
