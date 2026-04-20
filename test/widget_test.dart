// This is a basic Flutter widget test for the CRBS app.
//
// The default test referenced 'MyApp' which no longer exists.
// We renamed it to 'CRBSApp' in main.dart, so we update it here too.


import 'package:flutter_test/flutter_test.dart';

import 'package:crbs/main.dart'; // imports CRBSApp from main.dart

void main() {
  testWidgets('CRBS app smoke test', (WidgetTester tester) async {
    // Build the CRBSApp and trigger a frame.
    // CRBSApp is the root widget defined in main.dart.
    await tester.pumpWidget(const CRBSApp()); // ← was MyApp(), now CRBSApp()

    // The login page should show the 'CRBS' title text.
    // Update these expects to match what your LoginPage actually renders.
    expect(find.text('CRBS'), findsOneWidget);
  });
}