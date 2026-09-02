/// Helper utility for chemical atomic numbers and atomic data.
class AtomicUtils {
  static const Map<String, int> elementAtomicNumbers = {
    'H': 1, 'He': 2, 'Li': 3, 'Be': 4, 'B': 5, 'C': 6, 'N': 7, 'O': 8, 'F': 9, 'Ne': 10,
    'Na': 11, 'Mg': 12, 'Al': 13, 'Si': 14, 'P': 15, 'S': 16, 'Cl': 17, 'Ar': 18, 'K': 19, 'Ca': 20,
    'Sc': 21, 'Ti': 22, 'V': 23, 'Cr': 24, 'Mn': 25, 'Fe': 26, 'Co': 27, 'Ni': 28, 'Cu': 29, 'Zn': 30,
    'Ga': 31, 'Ge': 32, 'As': 33, 'Se': 34, 'Br': 35, 'Kr': 36, 'Rb': 37, 'Sr': 38, 'Y': 39, 'Zr': 40,
    'Ag': 47, 'Cd': 48, 'In': 49, 'Sn': 50, 'Sb': 51, 'Te': 52, 'I': 53, 'Xe': 54, 'Cs': 55, 'Ba': 56,
    'Pt': 78, 'Au': 79, 'Hg': 80, 'Tl': 81, 'Pb': 82, 'Bi': 83, 'Th': 90, 'U': 92, 'Pu': 94,
  };

  /// Calculates or looks up the atomic number (proton count Z) for any chemical formula.
  static int getAtomicNumber(String formula, {int? explicitAtomicNumber}) {
    if (explicitAtomicNumber != null && explicitAtomicNumber > 0) {
      return explicitAtomicNumber;
    }

    // Clean formula of charge symbols, parentheses, dots
    String clean = formula
        .replaceAll('₀', '0')
        .replaceAll('₁', '1')
        .replaceAll('₂', '2')
        .replaceAll('₃', '3')
        .replaceAll('₄', '4')
        .replaceAll('₅', '5')
        .replaceAll('₆', '6')
        .replaceAll('₇', '7')
        .replaceAll('₈', '8')
        .replaceAll('₉', '9')
        .replaceAll(RegExp(r'[⁺⁻+\-()·.,\s]'), '');

    // Match Element symbols and counts
    final regExp = RegExp(r'([A-Z][a-z]?)(\d*)');
    final matches = regExp.allMatches(clean);

    int totalProtons = 0;
    for (final m in matches) {
      final elem = m.group(1);
      final countStr = m.group(2);
      if (elem != null && elementAtomicNumbers.containsKey(elem)) {
        final count = countStr != null && countStr.isNotEmpty ? int.parse(countStr) : 1;
        totalProtons += elementAtomicNumbers[elem]! * count;
      }
    }

    return totalProtons > 0 ? totalProtons : 1;
  }
}
