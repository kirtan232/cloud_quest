import 'package:cloud_functions/cloud_functions.dart';

/// What the trusted completeToday Function reported back.
class RewardResult {
  const RewardResult({
    required this.points,
    required this.badgeId,
    required this.alreadyCompleted,
  });

  final int points;
  final String? badgeId;

  /// True when the reward already existed, so nothing new was awarded.
  final bool alreadyCompleted;

  static RewardResult fromMap(Map<String, dynamic> data) => RewardResult(
    points: (data['points'] as num?)?.toInt() ?? 0,
    badgeId: data['badgeId'] as String?,
    alreadyCompleted: data['alreadyCompleted'] == true,
  );
}

/// Requests challenge completion. The client sends only the challenge ID;
/// the server decides the UID (from Auth), the points, and the badge.
abstract class RewardService {
  Future<RewardResult> completeChallenge();
}

class CallableRewardService implements RewardService {
  CallableRewardService({FirebaseFunctions? functions})
    : _completeToday = (functions ?? FirebaseFunctions.instance).httpsCallable(
        'completeToday',
      );

  final HttpsCallable _completeToday;

  @override
  Future<RewardResult> completeChallenge() async {
    final result = await _completeToday.call<Object?>({'challengeId': 'today'});
    // Platform channels return Map<Object?, Object?>, so convert explicitly.
    return RewardResult.fromMap(Map<String, dynamic>.from(result.data as Map));
  }
}

/// Short, safe message for a failed completion request.
String friendlyRewardError(Object error) {
  if (error is FirebaseFunctionsException) {
    switch (error.code) {
      case 'unauthenticated':
        return 'Your session expired. Sign in again to complete the challenge.';
      case 'failed-precondition':
        return 'No challenge is available today.';
      case 'invalid-argument':
        return 'That challenge can\'t be completed.';
      case 'unavailable':
      case 'deadline-exceeded':
      case 'internal':
        return 'Couldn\'t reach the server. Your progress is safe. Try again.';
    }
  }
  return 'Something went wrong. Your progress is safe. Try again.';
}
