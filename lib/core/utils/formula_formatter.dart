class FormulaFormatter {
  static final Set<String> elements = {
    'H', 'He', 'Li', 'Be', 'B', 'C', 'N', 'O', 'F', 'Ne', 'Na', 'Mg', 'Al', 'Si', 'P', 'S', 'Cl',
    'Ar', 'K', 'Ca', 'Sc', 'Ti', 'V', 'Cr', 'Mn', 'Fe', 'Co', 'Ni', 'Cu', 'Zn', 'Ga', 'Ge', 'As',
    'Se', 'Br', 'Kr', 'Rb', 'Sr', 'Y', 'Zr', 'Nb', 'Mo', 'Tc', 'Ru', 'Rh', 'Pd', 'Ag', 'Cd', 'In',
    'Sn', 'Sb', 'Te', 'I', 'Xe', 'Cs', 'Ba', 'La', 'Ce', 'Pr', 'Nd', 'Pm', 'Sm', 'Eu', 'Gd', 'Tb',
    'Dy', 'Ho', 'Er', 'Tm', 'Yb', 'Lu', 'Hf', 'Ta', 'W', 'Re', 'Os', 'Ir', 'Pt', 'Au', 'Hg', 'Tl',
    'Pb', 'Bi', 'Po', 'At', 'Rn', 'Fr', 'Ra', 'Ac', 'Th', 'Pa', 'U', 'Np', 'Pu', 'Am', 'Cm', 'Bk',
    'Cf', 'Es', 'Fm', 'Md', 'No', 'Lr', 'Rf', 'Db', 'Sg', 'Bh', 'Hs', 'Mt', 'Ds', 'Rg', 'Cn', 'Nh',
    'Fl', 'Mc', 'Lv', 'Ts', 'Og'
  };

  static final Map<String, String> lowerToProper = {
    for (var e in elements) e.toLowerCase(): e
  };

  /// Takes a chemical formula like "nacl", "cuso4", "h2o" and 
  /// formats it with proper casing: "NaCl", "CuSO4", "H2O".
  static String format(String input) {
    if (input.isEmpty) return input;
    
    StringBuffer result = StringBuffer();
    int i = 0;
    while (i < input.length) {
      String c = input[i];
      if (RegExp(r'[a-zA-Z]').hasMatch(c)) {
        String? tokenized = _tokenize(input.substring(i));
        if (tokenized != null) {
          result.write(tokenized);
          break; 
        } else {
          result.write(c.toUpperCase());
          i++;
        }
      } else {
        result.write(c);
        i++;
      }
    }
    return result.toString();
  }

  static String? _tokenize(String s) {
    if (s.isEmpty) return "";
    
    if (!RegExp(r'^[a-zA-Z]').hasMatch(s[0])) {
      int end = 1;
      while (end < s.length && !RegExp(r'[a-zA-Z]').hasMatch(s[end])) {
        end++;
      }
      String? rest = _tokenize(s.substring(end));
      if (rest != null) {
        return s.substring(0, end) + rest;
      }
      return null;
    }

    // Try 1-letter first (prioritize common elements like C, O, H, N, S, P)
    String oneLetter = s.substring(0, 1).toLowerCase();
    if (lowerToProper.containsKey(oneLetter)) {
      String proper = lowerToProper[oneLetter]!;
      String? rest = _tokenize(s.substring(1));
      if (rest != null) {
        return proper + rest;
      }
    }

    // If 1-letter failed (or wasn't viable for the rest of string), try 2-letter
    if (s.length >= 2) {
      String twoLetter = s.substring(0, 2).toLowerCase();
      if (lowerToProper.containsKey(twoLetter)) {
        String proper = lowerToProper[twoLetter]!;
        String? rest = _tokenize(s.substring(2));
        if (rest != null) {
          return proper + rest;
        }
      }
    }

    return null;
  }
}
