const PerishabilityEngine = require('../../utils/perishabilityEngine');

describe('PerishabilityEngine', () => {
    const NOW = new Date('2026-03-10T12:00:00Z');

    describe('calculateSafetyThreshold', () => {
        it('should return 6 hours for prepared_meal', () => {
            const threshold = PerishabilityEngine.calculateSafetyThreshold('prepared_meal', NOW);
            expect(threshold.getTime()).toBe(NOW.getTime() + 6 * 60 * 60 * 1000);
        });

        it('should return 48 hours for fresh_produce', () => {
            const threshold = PerishabilityEngine.calculateSafetyThreshold('fresh_produce', NOW);
            expect(threshold.getTime()).toBe(NOW.getTime() + 48 * 60 * 60 * 1000);
        });

        it('should return 720 hours (30 days) for packaged_food', () => {
            const threshold = PerishabilityEngine.calculateSafetyThreshold('packaged_food', NOW);
            expect(threshold.getTime()).toBe(NOW.getTime() + 720 * 60 * 60 * 1000);
        });

        it('should return 24 hours for bakery_item', () => {
            const threshold = PerishabilityEngine.calculateSafetyThreshold('bakery_item', NOW);
            expect(threshold.getTime()).toBe(NOW.getTime() + 24 * 60 * 60 * 1000);
        });

        it('should return 48 hours for dairy_product', () => {
            const threshold = PerishabilityEngine.calculateSafetyThreshold('dairy_product', NOW);
            expect(threshold.getTime()).toBe(NOW.getTime() + 48 * 60 * 60 * 1000);
        });

        it('should default to 4 hours for unknown food type', () => {
            const threshold = PerishabilityEngine.calculateSafetyThreshold('mystery_food', NOW);
            expect(threshold.getTime()).toBe(NOW.getTime() + 4 * 60 * 60 * 1000);
        });
    });

    describe('validateSafety', () => {
        it('should pass when pickup is within safe window for prepared_meal', () => {
            const preparedAt = NOW;
            const pickupUntil = new Date(NOW.getTime() + 5 * 60 * 60 * 1000); // 5h < 6h
            const result = PerishabilityEngine.validateSafety('prepared_meal', preparedAt, pickupUntil);
            expect(result.isValid).toBe(true);
            expect(result.translationKey).toBeNull();
        });

        it('should fail when pickup exceeds safe window for prepared_meal', () => {
            const preparedAt = NOW;
            const pickupUntil = new Date(NOW.getTime() + 8 * 60 * 60 * 1000); // 8h > 6h
            const result = PerishabilityEngine.validateSafety('prepared_meal', preparedAt, pickupUntil);
            expect(result.isValid).toBe(false);
            expect(result.translationKey).toBe('error_unsafe_donation');
            expect(result.details).toContain('prepared_meal');
        });

        it('should pass at exact threshold boundary for bakery_item', () => {
            const preparedAt = NOW;
            const pickupUntil = new Date(NOW.getTime() + 24 * 60 * 60 * 1000); // exactly 24h
            const result = PerishabilityEngine.validateSafety('bakery_item', preparedAt, pickupUntil);
            expect(result.isValid).toBe(true);
        });

        it('should fail 1ms past threshold for bakery_item', () => {
            const preparedAt = NOW;
            const pickupUntil = new Date(NOW.getTime() + 24 * 60 * 60 * 1000 + 1);
            const result = PerishabilityEngine.validateSafety('bakery_item', preparedAt, pickupUntil);
            expect(result.isValid).toBe(false);
        });

        it('should pass 48h window for fresh_produce', () => {
            const preparedAt = NOW;
            const pickupUntil = new Date(NOW.getTime() + 47 * 60 * 60 * 1000);
            const result = PerishabilityEngine.validateSafety('fresh_produce', preparedAt, pickupUntil);
            expect(result.isValid).toBe(true);
        });

        it('should fail fresh_produce with 72h window', () => {
            const preparedAt = NOW;
            const pickupUntil = new Date(NOW.getTime() + 72 * 60 * 60 * 1000);
            const result = PerishabilityEngine.validateSafety('fresh_produce', preparedAt, pickupUntil);
            expect(result.isValid).toBe(false);
        });

        it('should pass packaged_food with 29-day window', () => {
            const preparedAt = NOW;
            const pickupUntil = new Date(NOW.getTime() + 29 * 24 * 60 * 60 * 1000);
            const result = PerishabilityEngine.validateSafety('packaged_food', preparedAt, pickupUntil);
            expect(result.isValid).toBe(true);
        });

        it('should fail packaged_food with 31-day window', () => {
            const preparedAt = NOW;
            const pickupUntil = new Date(NOW.getTime() + 31 * 24 * 60 * 60 * 1000);
            const result = PerishabilityEngine.validateSafety('packaged_food', preparedAt, pickupUntil);
            expect(result.isValid).toBe(false);
        });

        it('should return safetyThreshold in result', () => {
            const preparedAt = NOW;
            const pickupUntil = new Date(NOW.getTime() + 1 * 60 * 60 * 1000);
            const result = PerishabilityEngine.validateSafety('prepared_meal', preparedAt, pickupUntil);
            expect(result.safetyThreshold).toBeInstanceOf(Date);
            expect(result.safetyThreshold.getTime()).toBe(NOW.getTime() + 6 * 60 * 60 * 1000);
        });

        it('should use 4h default for unknown food types', () => {
            const preparedAt = NOW;
            const pickupUntil = new Date(NOW.getTime() + 5 * 60 * 60 * 1000); // 5h > 4h default
            const result = PerishabilityEngine.validateSafety('unknown_type', preparedAt, pickupUntil);
            expect(result.isValid).toBe(false);
        });
    });
});
