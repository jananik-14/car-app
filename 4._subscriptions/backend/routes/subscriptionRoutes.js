const express = require('express');
const router = express.Router();
const subscriptionController = require('../controllers/subscriptionController');

router.get('/status/:phoneNumber', subscriptionController.getSubscriptionStatus);
router.post('/subscribe', subscriptionController.subscribe);

module.exports = router;
