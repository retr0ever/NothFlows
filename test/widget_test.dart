// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nothflows/main.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const NothFlowsApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // After splash, we should still see either the splash title or permissions screen
    final findsSplash = find.text('NothFlows');
    final findsPermissions = find.text('Permissions Required');
    expect(findsSplash.evaluate().isNotEmpty || findsPermissions.evaluate().isNotEmpty, isTrue);
  });
}
