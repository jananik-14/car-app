const Bid = require('../models/bidModel');

const ALLOWED_INCREMENTS = [2000, 5000, 10000];

// @desc    Place a new bid
// @route   POST /api/bid/place
// @access  Public
const placeBid = async (req, res) => {
    try {
        const { vehicleId, bidderPhoneNumber, bidAmount } = req.body;

        if (!vehicleId || !bidderPhoneNumber || bidAmount === undefined || bidAmount === null) {
            return res.status(400).json({
                success: false,
                message: 'vehicleId, bidderPhoneNumber, and bidAmount are required'
            });
        }

        const numericBidAmount = Number(bidAmount);
        if (isNaN(numericBidAmount) || numericBidAmount <= 0) {
            return res.status(400).json({
                success: false,
                message: 'Please provide a valid positive bid amount'
            });
        }

        // Query all bids for this vehicleId and find the highest bid amount (default 0 if none exist)
        const highestBidDoc = await Bid.findOne({ vehicleId }).sort({ bidAmount: -1 });
        const currentHighestBid = highestBidDoc ? highestBidDoc.bidAmount : 0;

        const validAllowedAmounts = ALLOWED_INCREMENTS.map(inc => currentHighestBid + inc);

        if (!validAllowedAmounts.includes(numericBidAmount)) {
            const formattedOptions = validAllowedAmounts
                .map(amt => `₹${amt.toLocaleString('en-IN')}`)
                .join(', ');

            return res.status(400).json({
                success: false,
                message: `Invalid bid amount. Allowed bid amounts are ${formattedOptions} (+₹2,000, +₹5,000, or +₹10,000 over current highest bid of ₹${currentHighestBid.toLocaleString('en-IN')})`,
                validAmounts: validAllowedAmounts
            });
        }

        // Mark any previous "highest" bid for this vehicleId as "outbid"
        await Bid.updateMany({ vehicleId, status: 'highest' }, { status: 'outbid' });

        // Generate a referenceId like "BID" + Date.now() last 8 digits
        const referenceId = `BID${Date.now().toString().slice(-8)}`;

        // Save new bid as status "highest"
        const newBid = await Bid.create({
            vehicleId,
            bidderPhoneNumber,
            bidAmount: numericBidAmount,
            referenceId,
            status: 'highest'
        });

        res.status(201).json({
            success: true,
            message: 'Bid placed successfully',
            data: {
                referenceId: newBid.referenceId,
                bidAmount: newBid.bidAmount,
                vehicleId: newBid.vehicleId,
                bidderPhoneNumber: newBid.bidderPhoneNumber,
                status: newBid.status,
                createdAt: newBid.createdAt
            }
        });
    } catch (error) {
        console.error(error);
        if (error.name === 'ValidationError') {
            const messages = Object.values(error.errors).map(val => val.message);
            return res.status(400).json({
                success: false,
                message: messages.join(', ')
            });
        }
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};

// @desc    Get allowed bid increment amounts
// @route   GET /api/bid/increments
// @access  Public
const getIncrements = async (req, res) => {
    try {
        res.status(200).json({
            success: true,
            data: ALLOWED_INCREMENTS
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};

// @desc    Get bidding status for a vehicle
// @route   GET /api/bid/status/:vehicleId
// @access  Public
const getBidStatus = async (req, res) => {
    try {
        const { vehicleId } = req.params;

        if (!vehicleId) {
            return res.status(400).json({
                success: false,
                message: 'Vehicle ID is required'
            });
        }

        // Returns all bids for that vehicle sorted by bidAmount descending
        const bids = await Bid.find({ vehicleId }).sort({ bidAmount: -1 });

        const currentHighestBid = bids.length > 0 ? bids[0].bidAmount : 0;
        const highestBidderPhoneNumber = bids.length > 0 ? bids[0].bidderPhoneNumber : null;

        res.status(200).json({
            success: true,
            message: 'Bid status fetched successfully',
            data: {
                vehicleId,
                currentHighestBid,
                highestBidderPhoneNumber,
                totalBids: bids.length,
                bids
            }
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};

// @desc    Get bid confirmation by reference ID
// @route   GET /api/bid/confirmation/:referenceId
// @access  Public
const getBidConfirmation = async (req, res) => {
    try {
        const { referenceId } = req.params;

        if (!referenceId) {
            return res.status(400).json({
                success: false,
                message: 'Reference ID is required'
            });
        }

        const bid = await Bid.findOne({ referenceId });

        if (!bid) {
            return res.status(404).json({
                success: false,
                message: 'Bid not found'
            });
        }

        res.status(200).json({
            success: true,
            message: 'Bid confirmation fetched successfully',
            data: bid
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};

module.exports = {
    placeBid,
    getIncrements,
    getBidStatus,
    getBidConfirmation
};
