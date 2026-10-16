const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    uid: { 
        type: String, 
        required: true, 
        unique: true, 
        index: true // ဒါလေးထည့်ပေးတာက User ရှာတဲ့အချိန် (findOne) မှာ အများကြီး ပိုမြန်စေပါတယ်
    },
    email: { 
        type: String, 
        required: true, 
        trim: true,     // အရှေ့အနောက်က space တွေကို ဖျက်ပေးတယ်
        lowercase: true // email တွေကို အမြဲတမ်း small letter နဲ့ပဲ သိမ်းပေးတယ်
    },
    displayName: { type: String },
    createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('User', userSchema);