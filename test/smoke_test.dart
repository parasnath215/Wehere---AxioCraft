import 'package:flutter_test/flutter_test.dart';
import 'package:wehere/main.dart';
import 'package:wehere/state/app_state.dart';
import 'package:wehere/state/auth_notifier.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Smoke Test: App boots and shows Splash Screen or Login', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const WehereApp(),
    );

    // Give time for initial futures to settle
    await tester.pumpAndSettle();

    // After booting, we expect to be on either the splash screen or the login screen.
    // The presence of any scaffold means the app rendered.
    expect(find.byType(Scaffold), findsWidgets);
    
    // We should not see an error screen
    expect(find.text('Error'), findsNothing);
  });
}
