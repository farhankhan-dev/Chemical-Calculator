import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chemi_calc/app/app.dart';
import 'package:chemi_calc/data/datasources/chemical_local_datasource.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    ChemicalLocalDatasource().setCacheForTesting([]);
  });

  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ChemiCalcApp());
    expect(find.text('Chemicalc'), findsOneWidget);

    // Advance 2.5s to pass splash screen animation and navigation
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    expect(find.text('ChemiCalc'), findsWidgets);
  });
}
