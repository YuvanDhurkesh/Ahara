const { GeoPointSchema } = require('../../models/_shared');

describe('GeoPointSchema', () => {
    test('should define type as String with enum ["Point"]', () => {
        expect(GeoPointSchema.type).toBeDefined();
        expect(GeoPointSchema.type.type).toBe(String);
        expect(GeoPointSchema.type.enum).toEqual(['Point']);
    });

    test('should define coordinates as array of Numbers', () => {
        expect(GeoPointSchema.coordinates).toBeDefined();
        expect(GeoPointSchema.coordinates.type).toEqual([Number]);
    });

    test('should have a validator on coordinates', () => {
        const { validator } = GeoPointSchema.coordinates.validate;
        expect(typeof validator).toBe('function');
    });

    test('should validate [lng, lat] pair with 2 elements', () => {
        const { validator } = GeoPointSchema.coordinates.validate;
        expect(validator([80.27, 13.08])).toBe(true);
    });

    test('should reject single-element array', () => {
        const { validator } = GeoPointSchema.coordinates.validate;
        expect(validator([80.27])).toBe(false);
    });

    test('should reject three-element array', () => {
        const { validator } = GeoPointSchema.coordinates.validate;
        expect(validator([80.27, 13.08, 100])).toBe(false);
    });

    test('should reject non-array value', () => {
        const { validator } = GeoPointSchema.coordinates.validate;
        expect(validator('not an array')).toBe(false);
    });

    test('should reject null value', () => {
        const { validator } = GeoPointSchema.coordinates.validate;
        expect(validator(null)).toBe(false);
    });

    test('should have correct validation error message', () => {
        const { message } = GeoPointSchema.coordinates.validate;
        expect(message).toBe('coordinates must be [lng, lat]');
    });
});
