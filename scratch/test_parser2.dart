import 'package:chemi_calc/core/utils/formula_parser.dart';

void main() {
  final parser = FormulaParser();
  final result = parser.parse("CuSO4.5H2O");
  print(result.molarMass);
  print(result.elementCounts);
}
