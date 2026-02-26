const express = require('express');
const router = express.Router();
const { translateText } = require('../services/translationService');

// POST /api/translate
// Used dynamically by the frontend for unknown localization keys
router.post('/', async (req, res) => {
    try {
        const { text, targetLang } = req.body;

        if (!text) {
            return res.status(400).json({ error: 'Text is required for translation' });
        }

        // The service automatically translates into all supported languages (hi, ta, te)
        const translations = await translateText(text);

        // If a specific targetLang was requested and exists, send only that
        if (targetLang && translations[targetLang]) {
            return res.json({ translatedText: translations[targetLang] });
        }

        // Otherwise return all translations
        return res.json(translations);
    } catch (error) {
        console.error("Dynamic Translation Error:", error);
        res.status(500).json({ error: "Translation service failed" });
    }
});

module.exports = router;
