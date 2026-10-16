// အပေါ်ဆုံးမှာ admin ကို require လုပ်ထားတာကို ဖြုတ်ပြီး getAuth ကို import လုပ်ပါ
const { getAuth } = require('firebase-admin/auth'); 
const User = require('../models/user_model');

exports.syncUser = async (req, res) => {
  try {
    // Header က လာတဲ့ Token ကို ရယူ
    // (အကယ်၍ header မှာ bearer မပါလာရင် error မတက်အောင် စစ်ပေးထားတာ ပိုကောင်းပါတယ်)
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ message: "No token provided" });
    }
    
    const token = authHeader.split('Bearer ')[1];
    
    // 1. Firebase Token ကို အရင် Verify လုပ်ပါ
    // ပြင်ထားတဲ့နေရာ - admin.auth() ကို getAuth() နဲ့ အစားထိုးလိုက်ပါပြီ
    const decodedToken = await getAuth().verifyIdToken(token);
    const { email, name, uid } = decodedToken;

    // 2. Database ထဲမှာ User ရှိမရှိ စစ်ပါ
    let user = await User.findOne({ uid: uid });

    if (!user) {
      // မရှိရင် အသစ်ဖန်တီးပါ
      user = new User({ email, displayName: name, uid });
      await user.save();
    }

    res.status(200).json(user);
  } catch (error) {
    // error.message ကို ထုတ်ပေးရင် ဘာကြောင့် error တက်လဲဆိုတာ ပိုသိရပါမယ်
    res.status(401).json({ message: "Invalid Token or Server Error", error: error.message });
  }
};