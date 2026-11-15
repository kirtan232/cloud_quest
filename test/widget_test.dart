import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cloud_quest/main.dart';
import 'package:cloud_quest/screens/sign_in_screen.dart';
import 'package:cloud_quest/services/auth_service.dart';

void main() {
  test('debug builds default to the Android emulator host alias', () {
    expect(emulatorHost, '10.0.2.2');
  });

  test('sign-in failures share one message (no account enumeration)', () {
    for (final code in [
      'invalid-credential',
      'user-not-found',
      'wrong-password',
    ]) {
      expect(
        friendlyAuthError(FirebaseAuthException(code: code)),
        'Wrong email or password.',
      );
    }
    expect(
      friendlyAuthError(FirebaseAuthException(code: 'something-new')),
      'Something went wrong. Please try again.',
    );
  });

  testWidgets('blank sign-in shows validation errors', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignInScreen()));
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    expect(find.text('Enter your email.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
  });

  testWidgets('create-account mode requires a 6+ character password', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SignInScreen()));
    await tester.tap(find.text('New here? Create an account'));
    await tester.pump();
    expect(find.text('Create your account'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'a@b.dev');
    await tester.enterText(find.byType(TextFormField).last, '123');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pump();
    expect(
      find.text('Password must be at least 6 characters.'),
      findsOneWidget,
    );
  });
}
