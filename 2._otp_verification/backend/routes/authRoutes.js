const express = require('express');
const router = express.Router();
const { generateOTP, verifyOTP, acceptTerms } = require('../controllers/authController');

router.post('/generate-otp', generateOTP);
router.post('/verify-otp', verifyOTP);
router.post('/accept-terms', acceptTerms);

module.exports = router;
