// This is a basic Flutter widget test for the CRBS app.
//
// The default test referenced 'MyApp' which no longer exists.
// We renamed it to 'CRBSApp' in main.dart, so we update it here too.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:crbs/pages/customer/customer_page.dart';

void main() {
  testWidgets('CRBS app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: CustomerPage()));

    expect(find.text('DRIVO'), findsOneWidget);
  });
}
