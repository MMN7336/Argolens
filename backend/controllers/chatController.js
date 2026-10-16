const axios = require('axios');

exports.handleChat = async (req, res) => {
    const { message } = req.body;
    const image = req.file;

    let contentParts = [{ "type": "text", "text": message || "ဒီအပင်က ဘာအပင်လဲ ပြောပြပေးပါ။" }];

    if (image) {
        const base64Image = image.buffer.toString('base64');
        contentParts.push({ "type": "image_url", "image_url": { "url": `data:image/jpeg;base64,${base64Image}` } });
    }

    try {
        const response = await axios.post(process.env.OPENROUTER_URL, {
            "model": "google/gemini-2.5-flash-image",
            "messages": [
                { "role": "system", "content": "You are a plant expert. ALWAYS answer in Burmese language (မြန်မာဘာသာစကားဖြင့်သာ ဖြေကြားပါ။)." },
                { "role": "user", "content": contentParts }
            ]
        }, {
            headers: { 
                "Authorization": `Bearer ${process.env.API_KEY}`,
                "HTTP-Referer": "http://localhost:3000",
                "X-Title": "Plant App"
            }
        });
        res.json({ response: response.data.choices[0].message.content });
    } catch (error) {
        res.status(500).json({ error: "Failed", details: error.message });
    }
};