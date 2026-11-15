import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/quest.dart';

/// Read-only access to the shared challenge and the caller's own progress.
/// The app never writes these documents: Firestore rules deny client writes,
/// and only the completeToday Cloud Function records rewards.
abstract class QuestService {
  /// Loads `challenges/today`; returns null if it doesn't exist.
  Future<Challenge?> loadChallenge();

  /// Live updates of `users/{uid}/progress/today`, so points and the badge
  /// appear as soon as the reward Function writes them.
  Stream<Progress> watchProgress(String uid);
}

class FirestoreQuestService implements QuestService {
  FirestoreQuestService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<Challenge?> loadChallenge() async {
    final snapshot = await _db
        .collection('challenges')
        .doc('today')
        .get()
        .timeout(const Duration(seconds: 10));
    return Challenge.fromMap(snapshot.data());
  }

  @override
  Stream<Progress> watchProgress(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection('progress')
      .doc('today')
      .snapshots()
      .map((snapshot) => Progress.fromMap(snapshot.data()));
}

/// Short, safe message for a failed read.
String friendlyReadError(Object error) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'You don\'t have access to this data. Try signing in again.';
      case 'unavailable':
        return 'Can\'t reach the server. Check your connection (and that the emulators are running).';
    }
  }
  if (error is TimeoutException) {
    return 'The server took too long to respond. Try again.';
  }
  return 'Couldn\'t load this right now. Try again.';
}
