import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

/// Signed-in home screen. Only reachable through the auth gate.
/// Task 4 adds the Firestore challenge + progress; Task 5 the reward button;
/// Task 6 the Quest Coach.
class ChallengeScreen extends StatelessWidget {
  const ChallengeScreen({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Quest'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: logOut,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Signed in as ${user.email ?? user.uid}'),
            const SizedBox(height: 16),
            Text(
              "Today's challenge",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Challenge prompt loads from Cloud Firestore.'),
          ],
        ),
      ),
    );
  }
}
