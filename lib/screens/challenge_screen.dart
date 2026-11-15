import 'package:flutter/material.dart';

import '../models/quest.dart';
import '../services/auth_service.dart';
import '../services/challenge_service.dart';

/// Signed-in home screen. Only reachable through the auth gate in app.dart.
/// Task 5 adds the reward button; Task 6 adds the Quest Coach.
class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({
    super.key,
    required this.uid,
    required this.userLabel,
    this.questService,
    this.onSignOut,
  });

  /// Verified Firebase Auth UID of the signed-in learner.
  final String uid;

  /// Shown as "Signed in as …" (email, or UID if there is no email).
  final String userLabel;

  /// Injected in tests; defaults to the real Firestore service.
  final QuestService? questService;
  final Future<void> Function()? onSignOut;

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  late final QuestService _quests =
      widget.questService ?? FirestoreQuestService();
  late Future<Challenge?> _challenge;
  late final Stream<Progress> _progress;

  @override
  void initState() {
    super.initState();
    _challenge = _quests.loadChallenge();
    _progress = _quests.watchProgress(widget.uid);
  }

  void _retryChallenge() {
    final reload = _quests.loadChallenge();
    setState(() {
      _challenge = reload;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Quest'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: widget.onSignOut ?? logOut,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Signed in as ${widget.userLabel}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            _ChallengeCard(future: _challenge, onRetry: _retryChallenge),
            const SizedBox(height: 12),
            _ProgressCard(stream: _progress),
          ],
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.future, required this.onRetry});

  final Future<Challenge?> future;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<Challenge?>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _LoadingRow(label: 'Loading today\'s challenge…');
            }
            if (snapshot.hasError) {
              debugPrint('Challenge read failed: ${snapshot.error}');
              return _ErrorBlock(
                message: friendlyReadError(snapshot.error!),
                onRetry: onRetry,
              );
            }
            final challenge = snapshot.data;
            if (challenge == null) {
              return _ErrorBlock(
                message: 'No challenge is available today. Check back later.',
                onRetry: onRetry,
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TODAY'S CHALLENGE",
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(challenge.title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(challenge.prompt, style: theme.textTheme.bodyLarge),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.stream});

  final Stream<Progress> stream;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<Progress>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              debugPrint('Progress read failed: ${snapshot.error}');
              return Text(
                friendlyReadError(snapshot.error!),
                style: TextStyle(color: theme.colorScheme.error),
              );
            }
            if (!snapshot.hasData) {
              return const _LoadingRow(label: 'Loading your progress…');
            }
            final progress = snapshot.data!;
            final badge = progress.badgeId;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your progress', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      progress.completed
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: progress.completed
                          ? Colors.green
                          : theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        progress.completed ? 'Completed' : 'Not completed yet',
                      ),
                    ),
                    Text(
                      '${progress.points} pts',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
                if (badge != null) ...[
                  const SizedBox(height: 8),
                  Chip(
                    avatar: const Text('🏅'),
                    label: Text('${badgeName(badge)} badge'),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      const SizedBox(width: 12),
      Expanded(child: Text(label)),
    ],
  );
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Retry'),
      ),
    ],
  );
}
