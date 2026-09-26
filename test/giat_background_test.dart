import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/widgets/giat_background.dart';

void main() {
  testWidgets('GiatBackground renders without error and paints correctly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 402,
          height: 874,
          child: GiatBackground(
            showBottomWaves: true,
            child: SizedBox.expand(),
          ),
        ),
      ),
    );

    expect(find.byType(GiatBackground), findsOneWidget);
  });
}
