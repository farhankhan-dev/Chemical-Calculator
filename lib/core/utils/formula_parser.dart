import '../../features/periodic_table/data/element_repository.dart';
import '../../features/periodic_table/models/element_model.dart';
import 'formula_formatter.dart';

/// Result container for chemical formula parsing.
class FormulaParseResult {
  final double molarMass;
  final Map<String, int> elementCounts;
  final String? error;

  bool get isValid => error == null;

  const FormulaParseResult.success({
    required this.molarMass,
    required this.elementCounts,
  }) : error = null;

  const FormulaParseResult.failure(this.error)
      : molarMass = 0.0,
        elementCounts = const {};
}

/// Chemical formula parser that calculates total molar mass and element counts
/// from formulas like H2O, NaCl, H2SO4, Ca(OH)2, Al2(SO4)3, C6H12O6, etc.
///
/// Uses [ElementRepository] as the single source of truth for atomic weights.
class FormulaParser {
  final ElementRepository _elementRepository;
  late final Map<String, ElementModel> _elementSymbolMap;

  FormulaParser({ElementRepository? elementRepository})
      : _elementRepository = elementRepository ?? ElementRepository() {
    _elementSymbolMap = {
      for (final elem in _elementRepository.getAllElements()) elem.symbol: elem
    };
  }

  /// Parses a chemical formula string and returns a [FormulaParseResult].
  FormulaParseResult parse(String rawFormula) {
    final formula = FormulaFormatter.format(rawFormula.trim());
    if (formula.isEmpty) {
      return const FormulaParseResult.failure('Please enter a chemical formula.');
    }

    try {
      final counts = _parseElementCounts(formula);
      if (counts.isEmpty) {
        return const FormulaParseResult.failure('Please enter a valid chemical formula.');
      }

      double totalMolarMass = 0.0;
      for (final entry in counts.entries) {
        final symbol = entry.key;
        final count = entry.value;
        final element = _elementSymbolMap[symbol];
        if (element == null) {
          return FormulaParseResult.failure(
            'Unknown element symbol "$symbol". Please check the formula.',
          );
        }
        totalMolarMass += element.atomicMass * count;
      }

      return FormulaParseResult.success(
        molarMass: totalMolarMass,
        elementCounts: counts,
      );
    } catch (e) {
      if (e is FormatException) {
        return FormulaParseResult.failure(e.message);
      }
      return const FormulaParseResult.failure('Please enter a valid chemical formula.');
    }
  }

  Map<String, int> _parseElementCounts(String formula) {
    final List<Map<String, int>> stack = [{}];
    int i = 0;
    final length = formula.length;
    int currentMultiplier = 1; // Used for leading coefficients and hydrates like 5 in .5H2O

    while (i < length) {
      final char = formula[i];

      if (char == '(' || char == '[' || char == '{') {
        stack.add({});
        i++;
      } else if (char == ')' || char == ']' || char == '}') {
        if (stack.length <= 1) {
          throw const FormatException('Unmatched closing bracket in formula.');
        }

        final top = stack.removeLast();
        i++;

        // Read optional subscript multiplier for this group
        int countStart = i;
        while (i < length && _isDigit(formula[i])) {
          i++;
        }
        int count = 1;
        if (i > countStart) {
          final parsed = int.tryParse(formula.substring(countStart, i));
          if (parsed == null || parsed <= 0) {
            throw const FormatException('Subscript must be greater than zero.');
          }
          count = parsed;
        }

        final currentTop = stack.last;
        top.forEach((symbol, elemCount) {
          currentTop[symbol] = (currentTop[symbol] ?? 0) + (elemCount * count);
        });
      } else if (_isUppercase(char)) {
        int symbolStart = i;
        i++;
        while (i < length && _isLowercase(formula[i])) {
          i++;
        }
        final symbol = formula.substring(symbolStart, i);

        // Read optional subscript count
        int countStart = i;
        while (i < length && _isDigit(formula[i])) {
          i++;
        }
        int count = 1;
        if (i > countStart) {
          final parsed = int.tryParse(formula.substring(countStart, i));
          if (parsed == null || parsed <= 0) {
            throw const FormatException('Subscript must be greater than zero.');
          }
          count = parsed;
        }

        final currentTop = stack.last;
        currentTop[symbol] = (currentTop[symbol] ?? 0) + (count * currentMultiplier);
      } else if (char == ' ' || char == '·' || char == '.') {
        // Handle dots or spaces, optionally followed by a hydrate coefficient
        i++;
        int countStart = i;
        while (i < length && _isDigit(formula[i])) {
          i++;
        }
        if (i > countStart) {
          final parsed = int.tryParse(formula.substring(countStart, i));
          if (parsed != null && parsed > 0) {
            currentMultiplier = parsed;
          }
        } else {
          currentMultiplier = 1; // Reset multiplier if no number follows
        }
      } else if (_isDigit(char)) {
        // Leading digit at the very beginning of a formula or chunk
        int countStart = i;
        while (i < length && _isDigit(formula[i])) {
          i++;
        }
        final parsed = int.tryParse(formula.substring(countStart, i));
        if (parsed != null && parsed > 0) {
          currentMultiplier = parsed;
        }
      } else {
        throw FormatException('Invalid character "$char" in formula.');
      }
    }

    if (stack.length > 1) {
      throw const FormatException('Unmatched opening bracket in formula.');
    }

    return stack.single;
  }

  bool _isUppercase(String char) {
    final code = char.codeUnitAt(0);
    return code >= 65 && code <= 90;
  }

  bool _isLowercase(String char) {
    final code = char.codeUnitAt(0);
    return code >= 97 && code <= 122;
  }

  bool _isDigit(String char) {
    final code = char.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }
}
