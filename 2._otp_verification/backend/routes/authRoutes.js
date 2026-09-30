const express = require('express');
const router = express.Router();
const { generateOTP, verifyOTP, acceptTerms, updateProfile } = require('../controllers/authController');
const { protect } = require('../middleware/authMiddleware');

router.post('/generate-otp', generateOTP);
router.post('/verify-otp', verifyOTP);
router.post('/accept-terms', acceptTerms);
router.post('/profile', protect, updateProfile);

module.exports = router;
