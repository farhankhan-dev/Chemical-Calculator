import 'dart:io';
import 'dart:convert';

void main() async {
  // 1. Rename Reverse to Molarity
  final oldDir = Directory('lib/features/reverse_calculator');
  final newDir = Directory('lib/features/molarity_calculator');
  if (oldDir.existsSync()) {
    oldDir.renameSync(newDir.path);
    print('Renamed directory to molarity_calculator');
  }

  final oldFile = File('lib/features/molarity_calculator/presentation/screens/reverse_calculator_screen.dart');
  final newFile = File('lib/features/molarity_calculator/presentation/screens/molarity_calculator_screen.dart');
  if (oldFile.existsSync()) {
    oldFile.renameSync(newFile.path);
    print('Renamed screen file to molarity_calculator_screen.dart');
  }

  // Update references in the renamed file
  if (newFile.existsSync()) {
    String content = newFile.readAsStringSync();
    content = content.replaceAll('ReverseCalculatorScreen', 'MolarityCalculatorScreen');
    content = content.replaceAll('_ReverseCalculatorScreenState', '_MolarityCalculatorScreenState');
    newFile.writeAsStringSync(content);
    print('Updated MolarityCalculatorScreen class name');
  }

  // Update calculators_screen.dart
  final calcScreenFile = File('lib/features/calculators/presentation/screens/calculators_screen.dart');
  if (calcScreenFile.existsSync()) {
    String content = calcScreenFile.readAsStringSync();
    content = content.replaceAll('reverse_calculator_screen.dart', 'molarity_calculator_screen.dart');
    content = content.replaceAll('ReverseCalculatorScreen', 'MolarityCalculatorScreen');
    content = content.replaceAll("import '../../reverse_calculator/presentation/screens/", "import '../../molarity_calculator/presentation/screens/");
    calcScreenFile.writeAsStringSync(content);
    print('Updated calculators_screen.dart imports');
  }

  // 2. Update chemicals.json
  final jsonFile = File('assets/data/chemicals.json');
  if (jsonFile.existsSync()) {
    String jsonString = jsonFile.readAsStringSync();
    List<dynamic> data = jsonDecode(jsonString);

    final elements = {
      'H': 1, 'He': 2, 'Li': 3, 'Be': 4, 'B': 5, 'C': 6, 'N': 7, 'O': 8, 'F': 9, 'Ne': 10,
      'Na': 11, 'Mg': 12, 'Al': 13, 'Si': 14, 'P': 15, 'S': 16, 'Cl': 17, 'Ar': 18, 'K': 19, 'Ca': 20,
      'Sc': 21, 'Ti': 22, 'V': 23, 'Cr': 24, 'Mn': 25, 'Fe': 26, 'Co': 27, 'Ni': 28, 'Cu': 29, 'Zn': 30,
      'Ga': 31, 'Ge': 32, 'As': 33, 'Se': 34, 'Br': 35, 'Kr': 36, 'Rb': 37, 'Sr': 38, 'Y': 39, 'Zr': 40,
      'Ag': 47, 'Cd': 48, 'In': 49, 'Sn': 50, 'Sb': 51, 'Te': 52, 'I': 53, 'Xe': 54, 'Cs': 55, 'Ba': 56,
      'Pt': 78, 'Au': 79, 'Hg': 80, 'Tl': 81, 'Pb': 82, 'Bi': 83, 'Th': 90, 'U': 92, 'Pu': 94
    };

    for (var item in data) {
      String formula = item['formula'] ?? '';
      // Remove all digits, parentheses, and subscripts/superscripts
      String baseFormula = formula.replaceAll(RegExp(r'[\d⁺⁻\+\-\(\)₂₃₄₅₆₇₈₉₀]+'), '');
      
      // If it's a known element or a diatomic element (like Cl2 -> Cl)
      if (elements.containsKey(baseFormula)) {
        item['atomicNumber'] = elements[baseFormula];
        int multiplier = 1;
        if (formula.contains('₂')) multiplier = 2;
        if (formula.contains('₃')) multiplier = 3;
        if (formula.contains('₄')) multiplier = 4;
        if (formula.contains('₈')) multiplier = 8;
        
        item['atomicMass'] = item['molecularWeight'] / multiplier;
      } else {
        item['atomicNumber'] = null;
        item['atomicMass'] = item['molecularWeight'];
      }
    }

    final encoder = JsonEncoder.withIndent('  ');
    jsonFile.writeAsStringSync(encoder.convert(data));
    print('Updated chemicals.json with accurate atomicNumber and atomicMass');
  }
}
