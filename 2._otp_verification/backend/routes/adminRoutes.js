const express = require('express');
const router = express.Router();
const {
    getClients,
    getActiveLogins,
    getProfileCompleted,
    getActivityHistory
} = require('../controllers/adminController');
const { adminMiddleware } = require('../middleware/adminMiddleware');

router.get('/clients', adminMiddleware, getClients);
router.get('/active-logins', adminMiddleware, getActiveLogins);
router.get('/profile-completed', adminMiddleware, getProfileCompleted);
router.get('/history', adminMiddleware, getActivityHistory);

module.exports = router;
