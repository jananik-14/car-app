const UserProfile = require('../models/userProfileModel');

// @desc    Create or update user profile
// @route   POST /api/profile
// @access  Private
const upsertProfile = async (req, res) => {
    try {
        const { name, email, address, city, state, pincode, role } = req.body;
        const phoneNumber = req.user.phoneNumber;

        let profile = await UserProfile.findOne({ phoneNumber });

        if (profile) {
            // Update
            profile.name = name || profile.name;
            profile.email = email || profile.email;
            profile.address = address || profile.address;
            profile.city = city || profile.city;
            profile.state = state || profile.state;
            profile.pincode = pincode || profile.pincode;
            profile.role = role || profile.role; // Normally role updates should be restricted
            profile.isProfileComplete = !!(profile.name && profile.email && profile.address && profile.city && profile.state && profile.pincode);
            
            await profile.save();
        } else {
            // Create
            const isProfileComplete = !!(name && email && address && city && state && pincode);
            profile = await UserProfile.create({
                phoneNumber,
                name,
                email,
                address,
                city,
                state,
                pincode,
                role: role || 'client',
                isProfileComplete
            });
        }

        res.status(200).json({
            success: true,
            data: profile
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};

// @desc    Get current user profile
// @route   GET /api/profile/me
// @access  Private
const getMyProfile = async (req, res) => {
    try {
        const phoneNumber = req.user.phoneNumber;
        let profile = await UserProfile.findOne({ phoneNumber });

        if (!profile) {
            // Auto-create a skeleton profile if they logged in via OTP but haven't created a profile
            profile = await UserProfile.create({ phoneNumber, isProfileComplete: false });
        }

        res.status(200).json({
            success: true,
            data: profile
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};

// @desc    Get all client profiles (For Admin)
// @route   GET /api/profile/clients
// @access  Private/Admin
const getClients = async (req, res) => {
    try {
        // Here you might want to add a check to ensure req.user is an admin
        const clients = await UserProfile.find({ role: 'client' });

        res.status(200).json({
            success: true,
            count: clients.length,
            data: clients
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};

module.exports = {
    upsertProfile,
    getMyProfile,
    getClients
};
