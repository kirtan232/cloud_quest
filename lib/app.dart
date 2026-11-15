import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'screens/challenge_screen.dart';
import 'screens/sign_in_screen.dart';

class CloudQuestApp extends StatelessWidget {
  const CloudQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cloud Quest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4B3CB8)),
      ),
      home: const AuthGate(),
    );
  }
}

/// Shows the sign-in screen or the challenge screen based on Firebase Auth
/// state, so signed-out users can never reach the challenge, coach, or reward.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null) return const SignInScreen();
        // Keyed by UID: signing out or switching accounts disposes the old
        // screen, clearing any private progress or coach text from the UI.
        return ChallengeScreen(
          key: ValueKey(user.uid),
          uid: user.uid,
          userLabel: user.email ?? user.uid,
        );
      },
    );
  }
}
