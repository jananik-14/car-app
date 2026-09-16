const OTP = require('../models/otpModel');
const User = require('../models/userModel');
const jwt = require('jsonwebtoken');
const { sendSMS } = require('../utils/smsService');

// @desc    Generate OTP (4-digit)
// @route   POST /api/auth/generate-otp
// @access  Public
const generateOTP = async (req, res) => {
    try {
        const { phoneNumber } = req.body;

        if (!phoneNumber) {
            return res.status(400).json({ success: false, message: 'Phone number is required' });
        }

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
        const { phoneNumber, otp } = req.body;

        if (!phoneNumber || !otp) {
            return res.status(400).json({ success: false, message: 'Phone number and OTP are required' });
        }

        if (otp.length !== 4) {
            return res.status(400).json({ success: false, message: 'OTP must be exactly 4 digits' });
        }

        // Find the OTP in database
        const otpRecord = await OTP.findOne({ phoneNumber });

        if (!otpRecord) {
            return res.status(400).json({ success: false, message: 'OTP expired or not found' });
        }

        if (otpRecord.otp !== otp) {
            return res.status(400).json({ success: false, message: 'Invalid OTP' });
        }

        // OTP is valid. Clean up from database
        await OTP.deleteOne({ _id: otpRecord._id });

        // Create or update the user
        let user = await User.findOne({ phoneNumber });
        if (!user) {
            user = await User.create({ phoneNumber, isVerified: true });
        } else {
            user.isVerified = true;
            await user.save();
        }

        // Generate JWT token
        const token = jwt.sign(
            { phoneNumber: user.phoneNumber, id: user._id },
            process.env.JWT_SECRET || 'secret_key_here',
            { expiresIn: '30d' }
        );

        res.status(200).json({
            success: true,
            message: 'OTP verified successfully',
            data: {
                token,
                user: { 
                    phoneNumber: user.phoneNumber,
                    isVerified: user.isVerified,
                    termsAccepted: user.termsAccepted
                }
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
        await user.save();

        res.status(200).json({
            success: true,
            message: 'Terms of use accepted successfully',
            data: {
                user: {
                    phoneNumber: user.phoneNumber,
                    isVerified: user.isVerified,
                    termsAccepted: user.termsAccepted
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
    acceptTerms
};
