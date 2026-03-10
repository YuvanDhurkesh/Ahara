import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/utils/validators.dart';

void main() {
  group('Validators - Aadhaar Validation', () {
    test('should return null for valid Aadhaar numbers', () {
      // 234567890124 is a known valid Aadhaar number (passes Verhoeff checksum)
      expect(Validators.validateAadhaar('234567890124'), isNull);
      expect(Validators.validateAadhaar('2345 6789 0124'), isNull);
    });

    test('should return error for null or empty values', () {
      expect(Validators.validateAadhaar(null), equals("Aadhaar number is required"));
      expect(Validators.validateAadhaar(''), equals("Aadhaar number is required"));
    });

    test('should return error for invalid lengths', () {
      expect(Validators.validateAadhaar('12345678901'), equals("Aadhaar number must be exactly 12 digits"));
      expect(Validators.validateAadhaar('1234567890123'), equals("Aadhaar number must be exactly 12 digits"));
    });

    test('should return error for non-numeric characters', () {
      expect(Validators.validateAadhaar('2345 6789 012a'), equals("Aadhaar number must contain only digits"));
      expect(Validators.validateAadhaar('23456789012a'), equals("Aadhaar number must contain only digits"));
    });

    test('should return error for invalid first digit', () {
      // Aadhaar cannot start with 0 or 1
      expect(Validators.validateAadhaar('023456789012'), equals("Aadhaar number is invalid (must start with 2-9)"));
      expect(Validators.validateAadhaar('123456789012'), equals("Aadhaar number is invalid (must start with 2-9)"));
    });

    test('should return error for structural (checksum) failure', () {
      // 2345 6789 0123 - changed last digit from 2 to 3 to fail checksum
      expect(Validators.validateAadhaar('2345 6789 0123'), contains("checksum failed"));
    });
  });
}
