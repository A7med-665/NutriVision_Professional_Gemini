import 'package:flutter_test/flutter_test.dart';
import 'package:nutrivision/app.dart';

void main() {
  testWidgets('dashboard renders branding and add meal action', (tester) async {
    await tester.pumpWidget(const NutriVisionApp());
    await tester.pumpAndSettle();
    expect(find.text('NutriVision'), findsOneWidget);
    expect(find.text('صحتك تبدأ باختيارك'), findsOneWidget);
    expect(find.text('إضافة وجبة'), findsOneWidget);
  });
}
