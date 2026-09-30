const Watchlist = require('../models/watchlistModel');

const formatPhone = (phone) => {
    if (!phone) return '';
    let cleaned = phone.toString().trim();
    if (!cleaned.startsWith('+91')) {
        cleaned = `+91${cleaned.replace(/^0+/, '')}`;
    }
    return cleaned;
};

const getPhone = (req) => {
    const raw = req.params.phoneNumber || req.body?.phoneNumber || req.user?.phoneNumber || '';
    return formatPhone(raw);
};

// @desc    Get user's watchlist
// @route   GET /api/watchlist/:phoneNumber?
// @access  Public/Private
const getWatchlist = async (req, res) => {
    try {
        const phoneNumber = getPhone(req);
        console.log(`[WATCHLIST API] Fetching watchlist for phone: "${phoneNumber}"`);
        
        const items = await Watchlist.find({ phoneNumber }).sort({ createdAt: -1 });
        res.status(200).json({ success: true, count: items.length, data: items });
    } catch (error) {
        console.error('[WATCHLIST API ERROR]', error);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};

// @desc    Add vehicle to watchlist
// @route   POST /api/watchlist/add
// @access  Public/Private
const addToWatchlist = async (req, res) => {
    try {
        const phoneNumber = getPhone(req);
        const { vehicleId } = req.body;
        
        console.log(`[WATCHLIST API ADD] Phone: "${phoneNumber}", vehicleId: "${vehicleId}"`);

        if (!phoneNumber || !vehicleId) {
            return res.status(400).json({ success: false, message: 'phoneNumber and vehicleId are required' });
        }

        const watchlistItem = await Watchlist.findOneAndUpdate(
            { phoneNumber, vehicleId },
            { phoneNumber, vehicleId },
            { upsert: true, new: true }
        );

        res.status(201).json({ success: true, data: watchlistItem });
    } catch (error) {
        console.error('[WATCHLIST API ADD ERROR]', error);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};

// @desc    Remove vehicle from watchlist
// @route   POST or DELETE /api/watchlist/remove
// @access  Public/Private
const removeFromWatchlist = async (req, res) => {
    try {
        const phoneNumber = getPhone(req);
        const { vehicleId } = req.body;

        console.log(`[WATCHLIST API REMOVE] Phone: "${phoneNumber}", vehicleId: "${vehicleId}"`);

        const watchlistItem = await Watchlist.findOneAndDelete({ phoneNumber, vehicleId });

        res.status(200).json({ success: true, message: 'Removed from watchlist' });
    } catch (error) {
        console.error('[WATCHLIST API REMOVE ERROR]', error);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};

module.exports = { getWatchlist, addToWatchlist, removeFromWatchlist };
