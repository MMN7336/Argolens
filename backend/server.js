require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const { initializeApp, cert } = require('firebase-admin/app');

// Firebase Service Account
const serviceAccount = require('./firebase-service-account.json');

// Initialize Firebase App
initializeApp({
    credential: cert(serviceAccount)
});

const app = express();

app.use(cors());
app.use(express.json());

// MongoDB Connection
mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log("🍃 MongoDB Connected Successfully!"))
  .catch(err => console.error("❌ MongoDB Connection Error:", err));

// Routes
const authRoutes = require('./routes/auth');
app.use('/auth', authRoutes);

// Server Listen
const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Server is running on port ${PORT}`);
});