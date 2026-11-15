import 'package:flutter/material.dart';

import '../models/quest.dart';
import '../services/auth_service.dart';
import '../services/challenge_service.dart';
import '../services/reward_service.dart';

/// Signed-in home screen. Only reachable through the auth gate in app.dart.
/// Task 6 adds the Quest Coach.
class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({
    super.key,
    required this.uid,
    required this.userLabel,
    this.questService,
    this.rewardService,
    this.onSignOut,
  });

  /// Verified Firebase Auth UID of the signed-in learner.
  final String uid;

  /// Shown as "Signed in as …" (email, or UID if there is no email).
  final String userLabel;

  /// Injected in tests; defaults to the real Firestore service.
  final QuestService? questService;
  final RewardService? rewardService;
  final Future<void> Function()? onSignOut;

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  late final QuestService _quests =
      widget.questService ?? FirestoreQuestService();
  late Future<Challenge?> _challenge;
  late final Stream<Progress> _progress;
  late final RewardService _rewards =
      widget.rewardService ?? CallableRewardService();

  bool _isCompleting = false;
  _Status? _completeStatus;

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

  /// Explicit learner action: the only path that can request a reward.
  /// The button stays usable after completion so a retry can be shown to
  /// return the existing reward instead of adding points.
  Future<void> _complete() async {
    setState(() {
      _isCompleting = true;
      _completeStatus = null;
    });
    try {
      final result = await _rewards.completeChallenge();
      if (!mounted) return;
      final badge = result.badgeId == null ? '' : badgeName(result.badgeId!);
      setState(() {
        _completeStatus = result.alreadyCompleted
            ? _Status.info(
                'Already completed. You still have ${result.points} points; '
                'no extra points were awarded.',
              )
            : _Status.success(
                '+${result.points} points! You earned the $badge badge.',
              );
      });
    } catch (error) {
      debugPrint('completeToday failed: $error');
      if (!mounted) return;
      setState(
        () => _completeStatus = _Status.error(friendlyRewardError(error)),
      );
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
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
            FilledButton.icon(
              onPressed: _isCompleting ? null : _complete,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              icon: _isCompleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.flag),
              label: Text(_isCompleting ? 'Completing…' : 'Complete challenge'),
            ),
            if (_completeStatus != null) ...[
              const SizedBox(height: 8),
              _StatusBanner(status: _completeStatus!),
            ],
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

enum _Tone { success, info, error }

class _Status {
  const _Status._(this.tone, this.message);
  const _Status.success(String message) : this._(_Tone.success, message);
  const _Status.info(String message) : this._(_Tone.info, message);
  const _Status.error(String message) : this._(_Tone.error, message);

  final _Tone tone;
  final String message;
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});

  final _Status status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, background, foreground) = switch (status.tone) {
      _Tone.success => (
        Icons.celebration,
        Colors.green.shade50,
        Colors.green.shade900,
      ),
      _Tone.info => (
        Icons.info_outline,
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      _Tone.error => (
        Icons.error_outline,
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: foreground),
            const SizedBox(width: 10),
            Expanded(
              child: Text(status.message, style: TextStyle(color: foreground)),
            ),
          ],
        ),
      ),
    );
  }
}
