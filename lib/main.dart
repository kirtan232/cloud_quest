import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

/// Host the app uses to reach the Firebase emulators on the dev computer.
/// 10.0.2.2 is the Android emulator's alias for the host machine.
/// For a physical device, run with:
///   `flutter run --dart-define=EMULATOR_HOST=192.168.x.x` (your LAN IP)
const String emulatorHost = String.fromEnvironment(
  'EMULATOR_HOST',
  defaultValue: '10.0.2.2',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Debug builds talk to the local Emulator Suite, never production.
  // Each service is connected once, before any Auth/Firestore/Functions call.
  if (kDebugMode) {
    await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
    FirebaseFunctions.instance.useFunctionsEmulator(emulatorHost, 5001);
  }

  runApp(const CloudQuestApp());
}

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
      home: const SetupCheckScreen(),
    );
  }
}

/// Temporary first screen for Task 1: proves Firebase initialized and shows
/// which backend the app is pointed at. Task 3 replaces it with the auth gate.
class SetupCheckScreen extends StatelessWidget {
  const SetupCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = Firebase.app();
    final target = kDebugMode
        ? 'Local emulators at $emulatorHost'
        : 'Production project';
    return Scaffold(
      appBar: AppBar(title: const Text('Cloud Quest')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Firebase is connected',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text('Project: ${app.options.projectId}'),
            Text('Backend: $target'),
          ],
        ),
      ),
    );
  }
}
