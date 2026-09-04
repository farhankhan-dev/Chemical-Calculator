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
    
    // Attempt to tokenize the entire string as a chemical formula.
    String? tokenized = _tokenize(input);
    
    // If it successfully tokenizes the whole string, return the formatted version.
    // If it fails (meaning there are letters that don't match elements), 
    // we return the original input, which will naturally fail parsing later.
    if (tokenized != null && tokenized.length == input.length) {
       return tokenized;
    }
    
    // If we can't fully tokenize it, return the original input so it fails validation.
    return input;
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

    // 1. Try 2-letter exact casing match first (respect user input like "Co" vs "CO")
    if (s.length >= 2) {
      String twoOriginal = s.substring(0, 2);
      if (elements.contains(twoOriginal)) {
        String? rest = _tokenize(s.substring(2));
        if (rest != null) {
          return twoOriginal + rest;
        }
      }
    }

    // 2. Try 1-letter exact casing match
    String oneOriginal = s.substring(0, 1);
    if (elements.contains(oneOriginal)) {
      String? rest = _tokenize(s.substring(1));
      if (rest != null) {
        return oneOriginal + rest;
      }
    }

    // 3. Try 2-letter guessed match (e.g. user typed "cu", we guess "Cu")
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

    // 4. Try 1-letter guessed match (e.g. user typed "c", we guess "C")
    String oneLetter = s.substring(0, 1).toLowerCase();
    if (lowerToProper.containsKey(oneLetter)) {
      String proper = lowerToProper[oneLetter]!;
      String? rest = _tokenize(s.substring(1));
      if (rest != null) {
        return proper + rest;
      }
    }

    return null;
  }
}
