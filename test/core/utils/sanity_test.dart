// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:chemi_calc/core/utils/formula_formatter.dart';
import 'package:chemi_calc/core/utils/formula_parser.dart';

void main() {
  test('Test formatter and parser', () {
    print('Formatter CuSO4.5H2O: ${FormulaFormatter.format("CuSO4.5H2O")}');
    print('Formatter cuso4.5h2o: ${FormulaFormatter.format("cuso4.5h2o")}');
    final parser = FormulaParser();
    final res = parser.parse("CuSO4.5H2O");
    print('Parser CuSO4.5H2O: ${res.molarMass}');
    print('Element counts: ${res.elementCounts}');
    print('Parser cuso4.5h2o: ${parser.parse("cuso4.5h2o").molarMass}');
  });
}
