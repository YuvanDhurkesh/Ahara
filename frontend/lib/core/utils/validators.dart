class Validators {
  static const List<List<int>> _multiplicationTable = [
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

  static const List<List<int>> _permutationTable = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    [1, 5, 7, 6, 2, 8, 3, 0, 9, 4],
    [5, 8, 0, 3, 7, 9, 6, 1, 4, 2],
    [8, 9, 1, 6, 0, 4, 3, 5, 2, 7],
    [9, 4, 5, 3, 1, 2, 6, 8, 7, 0],
    [4, 2, 8, 6, 5, 7, 3, 9, 0, 1],
    [2, 7, 9, 3, 8, 0, 6, 4, 1, 5],
    [7, 0, 4, 6, 9, 1, 3, 2, 5, 8]
  ];

  static const List<int> _inverseTable = [0, 4, 3, 2, 1, 5, 6, 7, 8, 9];

  /// Validates Aadhaar number using Verhoeff algorithm and syntax rules.
  /// 1. Exactly 12 digits.
  /// 2. Only numeric characters.
  /// 3. First digit between 2 and 9.
  /// 4. Pass Verhoeff checksum.
  static String? validateAadhaar(String? value) {
    if (value == null || value.isEmpty) {
      return "Aadhaar number is required";
    }

    final aadhaar = value.replaceAll(RegExp(r'\s+'), '');

    if (aadhaar.length != 12) {
      return "Aadhaar number must be exactly 12 digits";
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(aadhaar)) {
      return "Aadhaar number must contain only digits";
    }

    int firstDigit = int.parse(aadhaar[0]);
    if (firstDigit < 2 || firstDigit > 9) {
      return "Aadhaar number is invalid (must start with 2-9)";
    }

    if (!_validateVerhoeff(aadhaar)) {
      return "Aadhaar number is structurally invalid (checksum failed)";
    }

    return null;
  }

  static bool _validateVerhoeff(String value) {
    int c = 0;
    List<int> digits = value.split('').map((e) => int.parse(e)).toList();
    List<int> reversedDigits = digits.reversed.toList();

    for (int i = 0; i < reversedDigits.length; i++) {
      c = _multiplicationTable[c][_permutationTable[i % 8][reversedDigits[i]]];
    }

    return c == 0;
  }
}
