import '../../features/periodic_table/data/element_repository.dart';
import '../../features/periodic_table/models/element_model.dart';
import 'formula_formatter.dart';
import 'profanity_filter.dart';

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
    if (ProfanityFilter.containsBannedWord(rawFormula)) {
      return const FormulaParseResult.failure('Please enter a valid chemical formula.');
    }

    // Normalize Unicode subscript digits (₀₁₂₃₄₅₆₇₈₉) to regular digits
    final normalized = rawFormula.trim()
        .replaceAll('₀', '0')
        .replaceAll('₁', '1')
        .replaceAll('₂', '2')
        .replaceAll('₃', '3')
        .replaceAll('₄', '4')
        .replaceAll('₅', '5')
        .replaceAll('₆', '6')
        .replaceAll('₇', '7')
        .replaceAll('₈', '8')
        .replaceAll('₉', '9');
    final formula = FormulaFormatter.format(normalized);
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
    final Map<String, int> totalCounts = {};
    // Replace '·' with '.' for unified splitting
    final normalizedForSplit = formula.replaceAll('·', '.');
    final segments = normalizedForSplit.split('.');
    
    if (segments.isEmpty) {
      throw const FormatException('Empty formula.');
    }
    
    for (final segment in segments) {
      final trimmedSegment = segment.trim();
      if (trimmedSegment.isEmpty) {
        throw const FormatException('Empty segment in formula (e.g., trailing dot).');
      }
      
      // Extract leading integer
      int i = 0;
      while (i < trimmedSegment.length && _isDigit(trimmedSegment[i])) {
        i++;
      }
      
      int coefficient = 1;
      String subFormula = trimmedSegment;
      if (i > 0) {
        final parsed = int.tryParse(trimmedSegment.substring(0, i));
        subFormula = trimmedSegment.substring(i).trim();
        if (parsed != null && parsed > 0) {
          coefficient = parsed;
        } else {
          if (parsed == 0 && subFormula.isEmpty) {
            throw FormatException("This formula has a decimal number, which isn't allowed. Rewrite it using whole numbers instead — for example, multiplying '\$formula' by 2.");
          }
          throw FormatException('Invalid leading coefficient in segment "$trimmedSegment".');
        }
      }
      
      if (subFormula.isEmpty) {
        if (RegExp(r'^\d+$').hasMatch(trimmedSegment)) {
          throw FormatException("This formula has a decimal number, which isn't allowed. Rewrite it using whole numbers instead — for example, multiplying '\$formula' by 2.");
        }
        throw FormatException('Segment "$trimmedSegment" has no chemical elements.');
      }
      
      final segmentCounts = _parseSegmentCounts(subFormula);
      
      final segmentCountsAfter = <String, int>{};
      segmentCounts.forEach((symbol, count) {
        final applied = count * coefficient;
        segmentCountsAfter[symbol] = applied;
        totalCounts[symbol] = (totalCounts[symbol] ?? 0) + applied;
      });
    }
    
    return totalCounts;
  }

  Map<String, int> _parseSegmentCounts(String formula) {
    final List<Map<String, int>> stack = [{}];
    int i = 0;
    final length = formula.length;

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
        currentTop[symbol] = (currentTop[symbol] ?? 0) + count;
      } else if (char == ' ') {
        i++;
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
