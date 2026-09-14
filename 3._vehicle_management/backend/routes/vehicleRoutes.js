const express = require('express');
const router = express.Router();
const {
    createVehicle,
    filterVehicles,
    getVehicleById,
    approveVehicle,
    setMaxPeople
} = require('../controllers/vehicleController');

// Routes
router.post('/post', createVehicle);
router.get('/filter', filterVehicles);
router.get('/:id', getVehicleById);
router.post('/:id/approve', approveVehicle);
router.post('/:id/setMaxPeople', setMaxPeople);

module.exports = router;
