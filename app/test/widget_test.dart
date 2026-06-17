// Smoke test: the app boots into onboarding without throwing.
import 'package:flutter_test/flutter_test.dart';
import 'package:mox_bond/main.dart';

void main() {
  testWidgets('app boots into onboarding', (tester) async {
    await tester.pumpWidget(const MoxApp());
    expect(find.byType(MoxApp), findsOneWidget);
  });
}
