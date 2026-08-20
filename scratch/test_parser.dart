import 'dart:io';
import '../lib/core/utils/formula_parser.dart';
import '../lib/core/utils/formula_formatter.dart';
import '../lib/features/periodic_table/data/element_repository.dart';

void main() {
  final parser = FormulaParser();
  
  // Test 1: Standard hydrate
  final r1 = parser.parse("H2SO4.6H2O");
  print("H2SO4.6H2O -> isValid: \${r1.isValid}, error: \${r1.error}, mass: \${r1.molarMass}, elements: \${r1.elementCounts}");

  // Test 2: User typo
  final r2 = parser.parse("H2SO4.6H20");
  print("H2SO4.6H20 -> isValid: \${r2.isValid}, error: \${r2.error}, mass: \${r2.molarMass}, elements: \${r2.elementCounts}");

  // Test 3: Formatting
  final fmt1 = FormulaFormatter.format("cuso4.5h2o");
  print("cuso4.5h2o formatted -> \$fmt1");
}
