const express = require('express');
const router = express.Router();
const {
    placeBid,
    getIncrements,
    getBidStatus,
    getBidConfirmation
} = require('../controllers/bidController');

// Routes
router.post('/place', placeBid);
router.get('/increments', getIncrements);
router.get('/status/:vehicleId', getBidStatus);
router.get('/confirmation/:referenceId', getBidConfirmation);

module.exports = router;
