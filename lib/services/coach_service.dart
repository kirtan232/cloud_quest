import 'package:cloud_functions/cloud_functions.dart';

const int maxQuestionLength = 300;

/// Asks the server-side Quest Coach for a hint. The app sends only the
/// question text; the server derives who is asking from Firebase Auth.
abstract class CoachService {
  Future<String> getQuestHint(String question);
}

class CallableCoachService implements CoachService {
  CallableCoachService({FirebaseFunctions? functions})
    : _askQuestCoach = (functions ?? FirebaseFunctions.instance).httpsCallable(
        'askQuestCoach',
      );

  final HttpsCallable _askQuestCoach;

  @override
  Future<String> getQuestHint(String question) async {
    final trimmed = question.trim();
    final safeQuestion = trimmed.length > maxQuestionLength
        ? trimmed.substring(0, maxQuestionLength)
        : trimmed;
    final result = await _askQuestCoach.call<Object?>({
      'question': safeQuestion,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    return data['reply'] as String;
  }
}

/// Short, safe message for a failed coach request.
String friendlyCoachError(Object error) {
  if (error is FirebaseFunctionsException) {
    switch (error.code) {
      case 'unauthenticated':
        return 'Sign in again to use the Quest Coach.';
      case 'invalid-argument':
        return 'Ask a question (up to $maxQuestionLength characters).';
    }
  }
  return 'The coach is unavailable. Try again.';
}
