const express = require('express');
const router = express.Router();
const watchlistController = require('../controllers/watchlistController');

router.get('/:phoneNumber', watchlistController.getWatchlist);
router.post('/add', watchlistController.addToWatchlist);
router.delete('/remove', watchlistController.removeFromWatchlist);

module.exports = router;
