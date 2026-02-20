/**
 * Multiplication table for Verhoeff algorithm
 */
const multiplicationTable = [
  [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
  [1, 2, 3, 4, 0, 6, 7, 8, 9, 5],
  [2, 3, 4, 0, 1, 7, 8, 9, 5, 6],
  [3, 4, 0, 1, 2, 8, 9, 5, 6, 7],
  [4, 0, 1, 2, 3, 9, 5, 6, 7, 8],
  [5, 9, 8, 7, 6, 0, 4, 3, 2, 1],
  [6, 5, 9, 8, 7, 1, 0, 4, 3, 2],
  [7, 6, 5, 9, 8, 2, 1, 0, 4, 3],
  [8, 7, 6, 5, 9, 3, 2, 1, 0, 4],
  [9, 8, 7, 6, 5, 4, 3, 2, 1, 0]
];

/**
 * Permutation table for Verhoeff algorithm
 */
const permutationTable = [
  [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
  [1, 5, 7, 6, 2, 8, 3, 0, 9, 4],
  [5, 8, 0, 3, 7, 9, 6, 1, 4, 2],
  [8, 9, 1, 6, 0, 4, 3, 5, 2, 7],
  [9, 4, 5, 3, 1, 2, 6, 8, 7, 0],
  [4, 2, 8, 6, 5, 7, 3, 9, 0, 1],
  [2, 7, 9, 3, 8, 0, 6, 4, 1, 5],
  [7, 0, 4, 6, 9, 1, 3, 2, 5, 8]
];

/**
 * Validates Aadhaar number syntax and Verhoeff checksum.
 * @param {string} aadhaarNumber 
 * @returns {{isValid: boolean, error?: string}}
 */
function validateAadhaar(aadhaarNumber) {
  if (!aadhaarNumber) {
    return { isValid: false, error: "Aadhaar number is required" };
  }

  // Remove whitespace
  const cleanedAadhaar = aadhaarNumber.toString().replace(/\s+/g, '');

  // Rule: Exactly 12 digits
  if (cleanedAadhaar.length !== 12) {
    return { isValid: false, error: "Aadhaar number must be exactly 12 digits" };
  }

  // Rule: Numeric characters only
  if (!/^[0-9]+$/.test(cleanedAadhaar)) {
    return { isValid: false, error: "Aadhaar number must contain only numeric digits" };
  }

  // Rule: First digit must be between 2 and 9
  const firstDigit = parseInt(cleanedAadhaar[0]);
  if (firstDigit < 2 || firstDigit > 9) {
    return { isValid: false, error: "Aadhaar number is invalid (must start with 2-9)" };
  }

  // Rule: Verhoeff Checksum
  if (!validateVerhoeff(cleanedAadhaar)) {
    return { isValid: false, error: "Aadhaar number failed checksum validation (invalid structure)" };
  }

  return { isValid: true };
}

/**
 * Verhoeff checksum calculation
 * @param {string} value 
 */
function validateVerhoeff(value) {
  let c = 0;
  const digits = value.split('').map(Number);
  const reversedDigits = digits.reverse();

  for (let i = 0; i < reversedDigits.length; i++) {
    c = multiplicationTable[c][permutationTable[i % 8][reversedDigits[i]]];
  }

  return c === 0;
}

module.exports = { validateAadhaar };
