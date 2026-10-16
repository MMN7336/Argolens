const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');
const upload = require('../middleware/upload');

router.post('/send', upload.single('image'), chatController.handleChat);
module.exports = router;