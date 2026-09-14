const Vehicle = require('../models/vehicleModel');

// @desc    Create a new vehicle (starts as "pending")
// @route   POST /api/vehicle/post
// @access  Public
const createVehicle = async (req, res) => {
    try {
        const {
            ownerPhoneNumber,
            make,
            model,
            year,
            km,
            engineNo,
            numberPlate,
            chassisNo,
            emdAmount,
            fineAmount,
            features,
            inspectionReport,
            state,
            fuelType,
            transmission,
            rtoCode,
            maxBidders
        } = req.body;

        if (!ownerPhoneNumber || !numberPlate || !chassisNo) {
            return res.status(400).json({
                success: false,
                message: 'ownerPhoneNumber, numberPlate, and chassisNo are required'
            });
        }

        const vehicle = await Vehicle.create({
            ownerPhoneNumber,
            make,
            model,
            year,
            km,
            engineNo,
            numberPlate,
            chassisNo,
            emdAmount,
            fineAmount,
            features: features || [],
            inspectionReport,
            state,
            fuelType,
            transmission,
            rtoCode,
            status: 'pending',
            maxBidders: maxBidders !== undefined ? maxBidders : 10,
            biddingEnabled: false,
            currentHighestBid: 0
        });

        res.status(201).json({
            success: true,
            message: 'Vehicle created successfully',
            data: vehicle
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

// @desc    List vehicles matching query filters (e.g. ?state=X&status=Y)
// @route   GET /api/vehicle/filter
// @access  Public
const filterVehicles = async (req, res) => {
    try {
        const queryObj = { ...req.query };
        const filter = {};

        // Filter by state (case-insensitive regex match or exact match)
        if (queryObj.state) {
            filter.state = new RegExp(`^${queryObj.state}$`, 'i');
        }

        // Filter by status
        if (queryObj.status) {
            filter.status = queryObj.status;
        }

        // Filter by fuelType
        if (queryObj.fuelType) {
            filter.fuelType = new RegExp(`^${queryObj.fuelType}$`, 'i');
        }

        // Filter by transmission
        if (queryObj.transmission) {
            filter.transmission = new RegExp(`^${queryObj.transmission}$`, 'i');
        }

        // Filter by make
        if (queryObj.make) {
            filter.make = new RegExp(`^${queryObj.make}$`, 'i');
        }

        // Filter by model
        if (queryObj.model) {
            filter.model = new RegExp(`^${queryObj.model}$`, 'i');
        }

        // Filter by ownerPhoneNumber
        if (queryObj.ownerPhoneNumber) {
            filter.ownerPhoneNumber = queryObj.ownerPhoneNumber;
        }

        const vehicles = await Vehicle.find(filter).sort({ createdAt: -1 });

        res.status(200).json({
            success: true,
            count: vehicles.length,
            message: 'Vehicles fetched successfully',
            data: vehicles
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};

// @desc    Get single vehicle by ID
// @route   GET /api/vehicle/:id
// @access  Public
const getVehicleById = async (req, res) => {
    try {
        const vehicle = await Vehicle.findById(req.params.id);

        if (!vehicle) {
            return res.status(404).json({
                success: false,
                message: 'Vehicle not found'
            });
        }

        res.status(200).json({
            success: true,
            message: 'Vehicle fetched successfully',
            data: vehicle
        });
    } catch (error) {
        console.error(error);
        if (error.name === 'CastError') {
            return res.status(404).json({
                success: false,
                message: 'Vehicle not found'
            });
        }
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};

// @desc    Approve or reject a vehicle
// @route   POST /api/vehicle/:id/approve
// @access  Public
const approveVehicle = async (req, res) => {
    try {
        const { decision } = req.body;

        if (!decision || !['approved', 'rejected'].includes(decision.toLowerCase())) {
            return res.status(400).json({
                success: false,
                message: 'Decision must be either "approved" or "rejected"'
            });
        }

        const vehicle = await Vehicle.findById(req.params.id);

        if (!vehicle) {
            return res.status(404).json({
                success: false,
                message: 'Vehicle not found'
            });
        }

        const normalizedDecision = decision.toLowerCase();
        if (normalizedDecision === 'approved') {
            vehicle.status = 'live';
            vehicle.biddingEnabled = true;
        } else {
            vehicle.status = 'rejected';
            vehicle.biddingEnabled = false;
        }

        await vehicle.save();

        res.status(200).json({
            success: true,
            message: `Vehicle ${normalizedDecision === 'approved' ? 'approved and made live' : 'rejected'} successfully`,
            data: vehicle
        });
    } catch (error) {
        console.error(error);
        if (error.name === 'CastError') {
            return res.status(404).json({
                success: false,
                message: 'Vehicle not found'
            });
        }
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};

// @desc    Set maximum number of bidders for a vehicle
// @route   POST /api/vehicle/:id/setMaxPeople
// @access  Public
const setMaxPeople = async (req, res) => {
    try {
        const { maxBidders } = req.body;

        if (maxBidders === undefined || isNaN(maxBidders) || Number(maxBidders) < 1) {
            return res.status(400).json({
                success: false,
                message: 'Please provide a valid positive number for maxBidders'
            });
        }

        const vehicle = await Vehicle.findById(req.params.id);

        if (!vehicle) {
            return res.status(404).json({
                success: false,
                message: 'Vehicle not found'
            });
        }

        vehicle.maxBidders = Number(maxBidders);
        await vehicle.save();

        res.status(200).json({
            success: true,
            message: 'Max bidders updated successfully',
            data: vehicle
        });
    } catch (error) {
        console.error(error);
        if (error.name === 'CastError') {
            return res.status(404).json({
                success: false,
                message: 'Vehicle not found'
            });
        }
        res.status(500).json({ success: false, message: 'Server Error' });
    }
};

module.exports = {
    createVehicle,
    filterVehicles,
    getVehicleById,
    approveVehicle,
    setMaxPeople
};
