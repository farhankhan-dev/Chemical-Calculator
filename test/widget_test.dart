import 'package:flutter_test/flutter_test.dart';
import 'package:chemi_calc/app/app.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ChemiCalcApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    // Verify splash screen elements are displayed
    expect(find.text('Chemi Calc'), findsOneWidget);
  });
}
