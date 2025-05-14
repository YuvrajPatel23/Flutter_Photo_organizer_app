import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c1/main.dart'; // adjust the path if needed

void main() {
  testWidgets('Photo Organizer loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Default'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
