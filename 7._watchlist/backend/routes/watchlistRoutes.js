const express = require('express');
const router = express.Router();
const { getWatchlist, addToWatchlist, removeFromWatchlist } = require('../controllers/watchlistController');

router.get('/:phoneNumber?', getWatchlist);
router.post('/add', addToWatchlist);
router.post('/remove', removeFromWatchlist);
router.delete('/remove', removeFromWatchlist);

module.exports = router;
