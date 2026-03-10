const perishabilityRules = require('../../config/perishabilityRules');

describe('Perishability Rules Config', () => {
    it('should define rules for prepared_meal as 6 hours', () => {
        expect(perishabilityRules.prepared_meal).toBe(6);
    });

    it('should define rules for fresh_produce as 48 hours', () => {
        expect(perishabilityRules.fresh_produce).toBe(48);
    });

    it('should define rules for packaged_food as 720 hours (30 days)', () => {
        expect(perishabilityRules.packaged_food).toBe(720);
    });

    it('should define rules for bakery_item as 24 hours', () => {
        expect(perishabilityRules.bakery_item).toBe(24);
    });

    it('should define rules for dairy_product as 48 hours', () => {
        expect(perishabilityRules.dairy_product).toBe(48);
    });

    it('should have exactly 5 food type rules', () => {
        expect(Object.keys(perishabilityRules)).toHaveLength(5);
    });

    it('should not have undefined values for any food type', () => {
        Object.values(perishabilityRules).forEach(value => {
            expect(value).toBeDefined();
            expect(typeof value).toBe('number');
            expect(value).toBeGreaterThan(0);
        });
    });
});
