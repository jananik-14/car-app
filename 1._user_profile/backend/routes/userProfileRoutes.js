const express = require('express');
const router = express.Router();
const {
    upsertProfile,
    getMyProfile,
    getClients
} = require('../controllers/userProfileController');
const { protect } = require('../middleware/authMiddleware');

router.post('/', protect, upsertProfile);
router.get('/me', protect, getMyProfile);
router.get('/clients', protect, getClients); // Typically protectAdmin

module.exports = router;
