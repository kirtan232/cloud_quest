import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cloud_quest/models/quest.dart';
import 'package:cloud_quest/screens/challenge_screen.dart';
import 'package:cloud_quest/services/challenge_service.dart';

/// In-memory QuestService so the screen can be tested without Firebase.
class FakeQuestService implements QuestService {
  FakeQuestService({this.challenge, this.challengeError});

  Challenge? challenge;
  Object? challengeError;
  int loadCalls = 0;
  final progress = StreamController<Progress>.broadcast();
  String? watchedUid;

  @override
  Future<Challenge?> loadChallenge() async {
    loadCalls++;
    if (challengeError != null) throw challengeError!;
    return challenge;
  }

  @override
  Stream<Progress> watchProgress(String uid) {
    watchedUid = uid;
    return progress.stream;
  }
}

const sample = Challenge(title: 'Guard the Treasure', prompt: 'Explain why…');

Widget host(FakeQuestService service) => MaterialApp(
  home: ChallengeScreen(
    uid: 'learner-1',
    userLabel: 'learner1@test.dev',
    questService: service,
    onSignOut: () async {},
  ),
);

void main() {
  group('Progress.fromMap', () {
    test('missing document means not completed, 0 points', () {
      final p = Progress.fromMap(null);
      expect(p.completed, isFalse);
      expect(p.points, 0);
      expect(p.badgeId, isNull);
    });

    test('reads the backend reward record', () {
      final p = Progress.fromMap({
        'completed': true,
        'points': 10,
        'badgeId': 'first-quest',
        'completedAt': Timestamp.fromDate(DateTime.utc(2026, 11, 14)),
      });
      expect(p.completed, isTrue);
      expect(p.points, 10);
      expect(badgeName(p.badgeId!), 'First Quest');
      expect(
        p.completedAt!.isAtSameMomentAs(DateTime.utc(2026, 11, 14)),
        isTrue,
      );
    });
  });

  test('Challenge.fromMap rejects missing or malformed data', () {
    expect(Challenge.fromMap(null), isNull);
    expect(Challenge.fromMap({'title': 'Only a title'}), isNull);
    expect(Challenge.fromMap({'title': 'T', 'prompt': 'P'})?.prompt, 'P');
  });

  testWidgets('shows the challenge and live progress for this learner', (
    tester,
  ) async {
    final service = FakeQuestService(challenge: sample);
    await tester.pumpWidget(host(service));
    expect(find.text('Loading your progress…'), findsOneWidget);

    await tester.pump();
    expect(find.text('Guard the Treasure'), findsOneWidget);
    expect(find.text('Signed in as learner1@test.dev'), findsOneWidget);
    expect(service.watchedUid, 'learner-1');

    service.progress.add(Progress.empty);
    await tester.pump();
    expect(find.text('Not completed yet'), findsOneWidget);
    expect(find.text('0 pts'), findsOneWidget);

    // Simulates the reward Function writing the progress document.
    service.progress.add(
      const Progress(completed: true, points: 10, badgeId: 'first-quest'),
    );
    await tester.pump();
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('10 pts'), findsOneWidget);
    expect(find.text('First Quest badge'), findsOneWidget);
  });

  testWidgets('missing challenge shows a message and Retry reloads', (
    tester,
  ) async {
    final service = FakeQuestService();
    await tester.pumpWidget(host(service));
    await tester.pump();
    expect(
      find.text('No challenge is available today. Check back later.'),
      findsOneWidget,
    );

    service.challenge = sample;
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();
    expect(service.loadCalls, 2);
    expect(find.text('Guard the Treasure'), findsOneWidget);
  });

  testWidgets('permission error shows a safe message', (tester) async {
    final service = FakeQuestService(
      challengeError: FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      ),
    );
    await tester.pumpWidget(host(service));
    await tester.pump();
    expect(
      find.text("You don't have access to this data. Try signing in again."),
      findsOneWidget,
    );
  });
}
