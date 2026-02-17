/**
 * Perishability Rules Database
 * 
 * Maps FoodType to maximum safe shelf life in hours.
 * Based on Ahara safety standards.
 */
const perishabilityRules = {
    "prepared_meal": 6,          // 6 hours
    "fresh_produce": 48,         // 2 days
    "packaged_food": 720,        // 30 days
    "bakery_item": 24,           // 1 day
    "dairy_product": 48          // 2 days
};

module.exports = perishabilityRules;
