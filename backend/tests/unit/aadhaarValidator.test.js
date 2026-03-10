const { validateAadhaar } = require('../../utils/aadhaarValidator');

describe('Aadhaar Validator', () => {
    describe('Syntax Validation', () => {
        it('should reject null/undefined input', () => {
            expect(validateAadhaar(null).isValid).toBe(false);
            expect(validateAadhaar(undefined).isValid).toBe(false);
            expect(validateAadhaar('').isValid).toBe(false);
        });

        it('should reject non-12-digit numbers', () => {
            expect(validateAadhaar('12345').isValid).toBe(false);
            expect(validateAadhaar('1234567890123').isValid).toBe(false);
            expect(validateAadhaar('12345678901').isValid).toBe(false);
        });

        it('should reject non-numeric characters', () => {
            const result = validateAadhaar('23456789012A');
            expect(result.isValid).toBe(false);
            expect(result.error).toMatch(/numeric/i);
        });

        it('should reject numbers starting with 0', () => {
            const result = validateAadhaar('012345678901');
            expect(result.isValid).toBe(false);
            expect(result.error).toMatch(/must start with 2-9/i);
        });

        it('should reject numbers starting with 1', () => {
            const result = validateAadhaar('112345678901');
            expect(result.isValid).toBe(false);
            expect(result.error).toMatch(/must start with 2-9/i);
        });

        it('should handle whitespace by stripping it', () => {
            // The validator strips whitespace before checking length
            // "2345 6789 0123" stripped = "234567890123" (12 digits, starts with 2)
            // It will then check Verhoeff — may or may not pass
            const result = validateAadhaar('2345 6789 0123');
            // Should not fail on syntax (length or format) — only possible fail is Verhoeff
            if (!result.isValid) {
                expect(result.error).toMatch(/checksum/i);
            }
        });
    });

    describe('Verhoeff Checksum', () => {
        it('should accept a known valid Aadhaar (234567890124)', () => {
            const result = validateAadhaar('234567890124');
            expect(result.isValid).toBe(true);
        });

        it('should reject invalid checksum', () => {
            // Take a valid number and change last digit
            const result = validateAadhaar('234567890125');
            expect(result.isValid).toBe(false);
            expect(result.error).toMatch(/checksum/i);
        });

        it('should accept number as string type', () => {
            const result = validateAadhaar('234567890124');
            expect(result.isValid).toBe(true);
        });
    });
});
