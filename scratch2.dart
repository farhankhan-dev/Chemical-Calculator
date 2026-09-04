import 'lib/core/utils/formula_parser.dart'; void main() { final result = FormulaParser().parse('SAMEEr'); print('Molar mass: ${result.molarMass}'); print('Error: ${result.error ?? 'none'}'); }
