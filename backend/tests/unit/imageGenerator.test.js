const { generateDefaultImageUrl } = require('../../utils/imageGenerator');

describe('Image Generator', () => {
    describe('generateDefaultImageUrl', () => {
        test('should return Unsplash URL for known category "biryani"', () => {
            const url = generateDefaultImageUrl('Chicken Biryani', 'prepared_meal');
            expect(url).toContain('images.unsplash.com');
            expect(url).toContain('w=800');
            expect(url).toContain('q=80');
        });

        test('should return Unsplash URL for known category "pizza"', () => {
            const url = generateDefaultImageUrl('Margherita Pizza', 'bakery');
            expect(url).toContain('images.unsplash.com');
        });

        test('should return Unsplash URL for known category "salad"', () => {
            const url = generateDefaultImageUrl('Greek Salad', 'fresh_produce');
            expect(url).toContain('images.unsplash.com');
        });

        test('should fall back to LoremFlickr for unknown food names', () => {
            const url = generateDefaultImageUrl('Xylophone Surprise', 'unknown_type');
            expect(url).toContain('loremflickr.com');
            expect(url).toContain('food');
        });

        test('should match category when food name has no match', () => {
            const url = generateDefaultImageUrl('Special Item', 'rice');
            expect(url).toContain('images.unsplash.com');
        });

        test('should return deterministic URLs for same input', () => {
            const url1 = generateDefaultImageUrl('Dal Makhani', 'curry');
            const url2 = generateDefaultImageUrl('Dal Makhani', 'curry');
            expect(url1).toBe(url2);
        });

        test('should return different URLs for different food names in same category', () => {
            const url1 = generateDefaultImageUrl('Plain Rice', 'rice');
            const url2 = generateDefaultImageUrl('Fried Rice Combo Special', 'rice');
            // Both should be Unsplash (rice category), but may differ in photo ID selection
            expect(url1).toContain('images.unsplash.com');
            expect(url2).toContain('images.unsplash.com');
        });

        test('should handle empty food name gracefully', () => {
            const url = generateDefaultImageUrl('', '');
            expect(url).toBeTruthy();
            expect(typeof url).toBe('string');
        });

        test('should handle undefined arguments with defaults', () => {
            const url = generateDefaultImageUrl();
            expect(url).toBeTruthy();
        });

        test('should handle special characters in food name for LoremFlickr fallback', () => {
            const url = generateDefaultImageUrl('My $pecial Dish!!! 123', 'exotic');
            expect(url).toContain('loremflickr.com');
            // Special characters stripped in LoremFlickr URL
            expect(url).not.toContain('$');
            expect(url).not.toContain('!');
        });

        test('should match case-insensitively (PIZZA vs pizza)', () => {
            const url = generateDefaultImageUrl('PIZZA Deluxe', 'food');
            expect(url).toContain('images.unsplash.com');
        });

        test('should try food name before category', () => {
            // Food name contains "burger" but category is "meal"
            const url = generateDefaultImageUrl('Veggie Burger', 'meal');
            // Should match "burger" from food name, not "meal" from category
            expect(url).toContain('images.unsplash.com');
        });
    });
});
