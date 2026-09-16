const express = require('express');
const router = express.Router();
const {
    placeBid,
    getIncrements,
    getBidStatus,
    getBidConfirmation
} = require('../controllers/bidController');
const { protect } = require('../middleware/authMiddleware');

// Routes
router.post('/place', protect, placeBid);
router.get('/increments', getIncrements);
router.get('/status/:vehicleId', getBidStatus);
router.get('/confirmation/:referenceId', protect, getBidConfirmation);

module.exports = router;
