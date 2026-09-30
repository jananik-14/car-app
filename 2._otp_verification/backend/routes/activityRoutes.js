const express = require('express');
const router = express.Router();
const { logActivity } = require('../controllers/adminController');

router.post('/log', logActivity);

module.exports = router;
