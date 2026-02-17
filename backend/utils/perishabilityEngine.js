const perishabilityRules = require("../config/perishabilityRules");

/**
 * Perishability Engine
 * 
 * Logic to calculate safe windows and validate donations.
 */
class PerishabilityEngine {
    /**
     * Calculate the recommended expiry date for a food item.
     * @param {string} foodType - The type of food (from enum)
     * @param {Date} preparedAt - The date the food was prepared
     * @returns {Date} - The safety threshold date
     */
    static calculateSafetyThreshold(foodType, preparedAt) {
        const hours = perishabilityRules[foodType] || 4; // Default to 4 hours if unknown
        const threshold = new Date(preparedAt);
        threshold.setHours(threshold.getHours() + hours);
        return threshold;
    }

    /**
     * Validate if a donation window is safe.
     * @param {string} foodType - The type of food
     * @param {Date} preparedAt - Preparation date
     * @param {Date} pickupUntil - Requested pickup deadline
     * @returns {Object} - { isValid: boolean, error: string|null, safetyThreshold: Date }
     */
    static validateSafety(foodType, preparedAt, pickupUntil) {
        const threshold = this.calculateSafetyThreshold(foodType, preparedAt);
        const pickupDate = new Date(pickupUntil);

        if (pickupDate > threshold) {
            return {
                isValid: false,
                translationKey: "error_unsafe_donation",
                details: `Proposed pickup time exceeds safety threshold for ${foodType} (${perishabilityRules[foodType]}h)`,
                safetyThreshold: threshold
            };
        }

        return {
            isValid: true,
            translationKey: null,
            details: "Safety validation passed",
            safetyThreshold: threshold
        };
    }
}

module.exports = PerishabilityEngine;
