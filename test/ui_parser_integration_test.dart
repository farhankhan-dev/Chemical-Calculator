import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chemi_calc/features/my_chemicals/presentation/widgets/add_edit_chemical_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Trace Add Chemical formula field parsing for CuSO4.5H2O', (WidgetTester tester) async {
    // Setup preferences for the app
    SharedPreferences.setMockInitialValues({});

    // Pump the dialog directly wrapped in MaterialApp
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: AddEditChemicalDialog(),
      ),
    ));
    await tester.pumpAndSettle();

    // Find the Formula text field in the AddEditChemicalDialog
    final formulaField = find.widgetWithText(TextFormField, 'e.g. NaCl, H2SO4, Ca(OH)2');
    expect(formulaField, findsOneWidget);

    await tester.enterText(formulaField, 'CuSO4.5H2O');
    
    // Pump to allow debounce timer in _onFormulaChanged to fire (500ms)
    await tester.pump(const Duration(milliseconds: 600));
  });
}
