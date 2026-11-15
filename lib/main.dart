import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Debug builds talk to the local Emulator Suite, never production.
  // Each service is connected once, before any Auth/Firestore/Functions call.
  if (kDebugMode) {
    await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
    FirebaseFunctions.instance.useFunctionsEmulator(emulatorHost, 5001);
  }

  runApp(const CloudQuestApp());
}
