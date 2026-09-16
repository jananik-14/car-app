const Watchlist = require('../models/Watchlist');

exports.getWatchlist = async (req, res) => {
    try {
        const { phoneNumber } = req.params;
        const watchlist = await Watchlist.find({ phoneNumber }).sort({ addedAt: -1 });
        
        res.status(200).json({ success: true, data: watchlist });
    } catch (error) {
        console.error('Error fetching watchlist:', error);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};

exports.addToWatchlist = async (req, res) => {
    try {
        const { phoneNumber, vehicleId } = req.body;
        
        if (!phoneNumber || !vehicleId) {
            return res.status(400).json({ success: false, message: 'Missing required fields' });
        }

        const newEntry = new Watchlist({
            phoneNumber,
            vehicleId
        });

        await newEntry.save();

        res.status(201).json({ success: true, message: 'Added to watchlist', data: newEntry });
    } catch (error) {
        if (error.code === 11000) {
            return res.status(400).json({ success: false, message: 'Vehicle already in watchlist' });
        }
        console.error('Error adding to watchlist:', error);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};

exports.removeFromWatchlist = async (req, res) => {
    try {
        const { phoneNumber, vehicleId } = req.body;
        
        if (!phoneNumber || !vehicleId) {
            return res.status(400).json({ success: false, message: 'Missing required fields' });
        }

        const result = await Watchlist.findOneAndDelete({ phoneNumber, vehicleId });
        
        if (!result) {
            return res.status(404).json({ success: false, message: 'Entry not found in watchlist' });
        }

        res.status(200).json({ success: true, message: 'Removed from watchlist' });
    } catch (error) {
        console.error('Error removing from watchlist:', error);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};
