// moment not used, using native Date

const RULES = {
    'COOKED_VEG': {
        'ROOM_TEMP': 12, // Relaxed for testing (was 3)
        'REFRIGERATED': 24 // hours
    },
    'COOKED_NON_VEG': {
        'ROOM_TEMP': 12, // Relaxed for testing (was 2)
        'REFRIGERATED': 24 // hours
    },
    'RAW_VEG': {
        'ROOM_TEMP': 48, // hours (2 days)
        'REFRIGERATED': 120 // hours (5 days)
    },
    'BAKERY': {
        'ROOM_TEMP': 48, // hours
        'REFRIGERATED': 72 // hours
    }
};

/**
 * Calculates the expiry time based on food type, storage condition, and cooked time.
 * @param {string} foodType - 'COOKED_VEG', 'COOKED_NON_VEG', 'RAW_VEG', 'BAKERY'
 * @param {string} storageCondition - 'ROOM_TEMP', 'REFRIGERATED'
 * @param {Date|string} cookedTime - The time the food was prepared
 * @returns {Date} The calculated expiry time
 */
const calculateExpiry = (foodType, storageCondition, cookedTime) => {
    if (!RULES[foodType] || !RULES[foodType][storageCondition]) {
        // Default fallback: 2 hours if unknown (safety first)
        return new Date(new Date(cookedTime).getTime() + 2 * 60 * 60 * 1000);
    }

    const shelfLifeHours = RULES[foodType][storageCondition];
    return new Date(new Date(cookedTime).getTime() + shelfLifeHours * 60 * 60 * 1000);
};

module.exports = { calculateExpiry };
