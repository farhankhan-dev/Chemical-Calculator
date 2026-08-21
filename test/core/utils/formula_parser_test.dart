import 'package:flutter_test/flutter_test.dart';
import 'package:chemi_calc/core/utils/formula_parser.dart';

void main() {
  late FormulaParser parser;

  setUp(() {
    parser = FormulaParser();
  });

  group('FormulaParser Valid Formulas', () {
    test('H2O', () {
      final res = parser.parse('H2O');
      expect(res.isValid, isTrue);
      expect(res.elementCounts, equals({'H': 2, 'O': 1}));
      // H: 1.008*2 = 2.016, O: 15.999 => 18.015
      expect(res.molarMass, closeTo(18.015, 0.001));
    });

    test('NaCl', () {
      final res = parser.parse('NaCl');
      expect(res.isValid, isTrue);
      expect(res.elementCounts, equals({'Na': 1, 'Cl': 1}));
      // Na: 22.990, Cl: 35.45 => 58.44
      expect(res.molarMass, closeTo(58.44, 0.01));
    });

    test('H2SO4', () {
      final res = parser.parse('H2SO4');
      expect(res.isValid, isTrue);
      expect(res.elementCounts, equals({'H': 2, 'S': 1, 'O': 4}));
      // H: 2.016 + S: 32.06 + O: 63.996 => 98.072
      expect(res.molarMass, closeTo(98.072, 0.01));
    });

    test('Ca(OH)2', () {
      final res = parser.parse('Ca(OH)2');
      expect(res.isValid, isTrue);
      expect(res.elementCounts, equals({'Ca': 1, 'O': 2, 'H': 2}));
      // Ca: 40.078 + O: 31.998 + H: 2.016 => 74.092
      expect(res.molarMass, closeTo(74.092, 0.01));
    });

    test('Al2(SO4)3', () {
      final res = parser.parse('Al2(SO4)3');
      expect(res.isValid, isTrue);
      expect(res.elementCounts, equals({'Al': 2, 'S': 3, 'O': 12}));
      // Al: 53.964 + S: 96.18 + O: 191.988 => 342.132
      expect(res.molarMass, closeTo(342.132, 0.01));
    });

    test('C6H12O6', () {
      final res = parser.parse('C6H12O6');
      expect(res.isValid, isTrue);
      expect(res.elementCounts, equals({'C': 6, 'H': 12, 'O': 6}));
      // C: 72.066 + H: 12.096 + O: 95.994 => 180.156
      expect(res.molarMass, closeTo(180.156, 0.01));
    });

    test('MgSO4.7H2O', () {
      final res = parser.parse('MgSO4.7H2O');
      expect(res.isValid, isTrue);
      expect(res.molarMass, closeTo(246.47, 0.01));
    });

    test('KAl(SO4)2.12H2O', () {
      final res = parser.parse('KAl(SO4)2.12H2O');
      expect(res.isValid, isTrue);
      expect(res.molarMass, closeTo(474.372, 0.01));
    });
  });

  group('FormulaParser Invalid Formulas', () {
    test('XYZ (Unknown element symbol)', () {
      final res = parser.parse('XYZ');
      expect(res.isValid, isFalse);
      expect(res.error, contains('Unknown element symbol'));
    });

    test('Unmatched closing parenthesis', () {
      final res = parser.parse('H2O)');
      expect(res.isValid, isFalse);
      expect(res.error, contains('Unmatched closing bracket'));
    });

    test('Unmatched opening parenthesis', () {
      final res = parser.parse('((NaCl');
      expect(res.isValid, isFalse);
      expect(res.error, contains('Unmatched opening bracket'));
    });

    test('Invalid character', () {
      final res = parser.parse('ABC123');
      expect(res.isValid, isFalse);
      expect(res.error, isNotNull);
    });

    test('Empty formula', () {
      final res = parser.parse('');
      expect(res.isValid, isFalse);
      expect(res.error, equals('Please enter a chemical formula.'));
    });
  });
}
