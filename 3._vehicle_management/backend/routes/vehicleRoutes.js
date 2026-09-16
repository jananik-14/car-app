const express = require('express');
const router = express.Router();
const {
    createVehicle,
    filterVehicles,
    getVehicleById,
    approveVehicle,
    setMaxPeople
} = require('../controllers/vehicleController');
const { protect } = require('../middleware/authMiddleware');

// Routes
router.post('/post', protect, createVehicle);
router.get('/filter', filterVehicles);
router.get('/:id', getVehicleById);
router.post('/:id/approve', protect, approveVehicle);
router.post('/:id/setMaxPeople', protect, setMaxPeople);

module.exports = router;
