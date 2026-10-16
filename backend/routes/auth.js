const express = require('express');
const router = express.Router();
const { getAuth } = require('firebase-admin/auth');
const User = require('../models/user_model'); // User Model ကို သေချာ import လုပ်ထားပါ

// Sync Route
router.post('/sync', async (req, res) => {
    try {
        const authHeader = req.headers.authorization;

        // ၁။ Header စစ်ဆေးခြင်း
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ message: "No token provided" });
        }

        const idToken = authHeader.split('Bearer ')[1];

        // ၂။ Firebase Token Verify လုပ်ခြင်း
        const decodedToken = await getAuth().verifyIdToken(idToken);
        const { uid, email, name } = decodedToken;

        // ၃။ MongoDB ထဲမှာ User ကို ရှာ/ထည့်ခြင်း (Upsert)
        // ဒီအပိုင်းက Collection ကို အလိုအလျောက် ဖန်တီးပေးပါလိမ့်မယ်
        const user = await User.findOneAndUpdate(
            { uid: uid }, // Search criteria
            { 
                $set: { 
                    email: email, 
                    displayName: name || "New User" 
                } 
            }, 
            { upsert: true, new: true, setDefaultsOnInsert: true } // မရှိရင် အသစ်ထည့်၊ ရှိရင် Update
        );

        console.log("✅ User Synced & Saved to DB:", uid);
        res.status(200).json({ message: "Sync Success", user: user });

    } catch (error) {
        console.error("❌ Sync Error:", error);
        res.status(500).json({ message: "Sync failed", error: error.message });
    }
});

module.exports = router;