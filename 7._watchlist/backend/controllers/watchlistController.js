const Watchlist = require('../models/watchlistModel');

// @desc    Get user's watchlist
// @route   GET /api/watchlist
// @access  Private
const getWatchlist = async (req, res) => {
    try {
        const watchlist = await Watchlist.find({ phoneNumber: req.user.phoneNumber });
        res.status(200).json({ success: true, data: watchlist });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};

// @desc    Add vehicle to watchlist
// @route   POST /api/watchlist/add
// @access  Private
const addToWatchlist = async (req, res) => {
    try {
        const { vehicleId } = req.body;
        
        if (!vehicleId) {
            return res.status(400).json({ success: false, message: 'vehicleId is required' });
        }

        const watchlistItem = await Watchlist.create({
            phoneNumber: req.user.phoneNumber,
            vehicleId
        });

        res.status(201).json({ success: true, data: watchlistItem });
    } catch (error) {
        if (error.code === 11000) {
            return res.status(400).json({ success: false, message: 'Vehicle already in watchlist' });
        }
        console.error(error);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};

// @desc    Remove vehicle from watchlist
// @route   POST /api/watchlist/remove
// @access  Private
const removeFromWatchlist = async (req, res) => {
    try {
        const { vehicleId } = req.body;

        const watchlistItem = await Watchlist.findOneAndDelete({
            phoneNumber: req.user.phoneNumber,
            vehicleId
        });

        if (!watchlistItem) {
            return res.status(404).json({ success: false, message: 'Not found in watchlist' });
        }

        res.status(200).json({ success: true, message: 'Removed from watchlist' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};

module.exports = { getWatchlist, addToWatchlist, removeFromWatchlist };
