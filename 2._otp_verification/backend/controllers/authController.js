const OTP = require('../models/otpModel');

// @desc    Generate OTP (4-digit)
// @route   POST /api/auth/generate-otp
// @access  Public
const generateOTP = async (req, res) => {
    try {
        const { phoneNumber } = req.body;

        if (!phoneNumber) {
            return res.status(400).json({ success: false, message: 'Phone number is required' });
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

        // In a real application, you would send this OTP via SMS here.
        // We will just return it in the response for development purposes.
        res.status(200).json({
            success: true,
            message: 'OTP generated successfully',
            data: {
                phoneNumber: otpRecord.phoneNumber,
                // Do not expose OTP in production, doing it here for testing
                otp: otpRecord.otp, 
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

        // Here you would typically generate and return a JWT token for the user
        res.status(200).json({
            success: true,
            message: 'OTP verified successfully',
            data: {
                // Mock JWT or user data here
                token: 'sample_jwt_token_here',
                user: { phoneNumber }
            }
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};

module.exports = {
    generateOTP,
    verifyOTP
};
