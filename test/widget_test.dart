import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:healthplate/main.dart';

void main() {
  testWidgets('DietRAO app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DietRAOApp());

    // Just verify the app loads without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
