import 'package:flutter_test/flutter_test.dart';
import 'package:giat/main.dart';

void main() {
  testWidgets('Giat app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GiatApp());
    expect(find.text('GIAT'), findsOneWidget);
    expect(find.text('Mulai Sekarang'), findsOneWidget);
  });
}
