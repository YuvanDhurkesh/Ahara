const translate = require('google-translate-api-x');

// Target languages we support
const TARGET_LANGS = ['hi', 'ta', 'te'];

/**
 * Translates text into the target languages (hi, ta, te).
 * Retries up to 2 times upon failure.
 * @param {string} text - The text to translate (assumed English).
 * @returns {Promise<Object>} An object containing the translations, e.g., { hi: '...', ta: '...', te: '...' }
 */
async function translateText(text) {
    if (!text || text.trim() === '') {
        return { hi: '', ta: '', te: '' };
    }

    const translations = {};
    const promises = TARGET_LANGS.map(async (lang) => {
        let attempts = 0;
        let success = false;

        while (attempts < 2 && !success) {
            attempts++;
            try {
                const res = await translate(text, { to: lang, autoCorrect: true });
                translations[lang] = res.text;
                success = true;
            } catch (error) {
                console.error(`Translation failed for ${lang} on attempt ${attempts}:`, error.message);
                if (attempts === 2) {
                    translations[lang] = text; // Fallback to original text after retries
                }
            }
        }
    });

    await Promise.all(promises);
    return translations;
}

module.exports = {
    translateText
};
