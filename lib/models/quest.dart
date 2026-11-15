import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

/// Shared challenge content from `challenges/today` (read-only for clients).
class Challenge {
  const Challenge({required this.title, required this.prompt});

  final String title;
  final String prompt;

  /// Returns null when the document is missing or malformed, so the UI can
  /// show a clear "no challenge" state instead of crashing.
  static Challenge? fromMap(Map<String, dynamic>? data) {
    final title = data?['title'];
    final prompt = data?['prompt'];
    if (title is! String || prompt is! String) return null;
    return Challenge(title: title, prompt: prompt);
  }
}

/// Private learner progress from `users/{uid}/progress/today`.
/// Written only by the trusted completeToday Cloud Function.
class Progress {
  const Progress({
    required this.completed,
    required this.points,
    this.badgeId,
    this.completedAt,
  });

  /// State before the learner has completed anything (no document yet).
  static const empty = Progress(completed: false, points: 0);

  final bool completed;
  final int points;
  final String? badgeId;
  final DateTime? completedAt;

  static Progress fromMap(Map<String, dynamic>? data) {
    if (data == null) return empty;
    final completedAt = data['completedAt'];
    return Progress(
      completed: data['completed'] == true,
      points: (data['points'] as num?)?.toInt() ?? 0,
      badgeId: data['badgeId'] as String?,
      completedAt: completedAt is Timestamp ? completedAt.toDate() : null,
    );
  }
}

/// Display names for badge IDs awarded by the backend.
String badgeName(String badgeId) => switch (badgeId) {
  'first-quest' => 'First Quest',
  _ => badgeId,
};
