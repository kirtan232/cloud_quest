import 'package:firebase_auth/firebase_auth.dart';

final FirebaseAuth auth = FirebaseAuth.instance;

Future<UserCredential> register(String email, String password) => auth
    .createUserWithEmailAndPassword(email: email.trim(), password: password);

Future<UserCredential> signIn(String email, String password) =>
    auth.signInWithEmailAndPassword(email: email.trim(), password: password);

Future<void> logOut() => auth.signOut();

/// Turns a FirebaseAuthException into a short, safe message for the UI.
/// Sign-in failures share one message so the app doesn't reveal whether an
/// email address has an account.
String friendlyAuthError(FirebaseAuthException error) {
  switch (error.code) {
    case 'invalid-credential':
    case 'user-not-found':
    case 'wrong-password':
      return 'Wrong email or password.';
    case 'email-already-in-use':
      return 'An account with that email already exists. Try signing in.';
    case 'invalid-email':
      return 'Enter a valid email address.';
    case 'weak-password':
      return 'Password must be at least 6 characters.';
    case 'too-many-requests':
      return 'Too many attempts. Wait a moment and try again.';
    case 'network-request-failed':
      return _networkMessage;
    case 'unknown':
    case 'internal-error':
      // On Android, an unreachable Auth server (e.g. emulators not started)
      // surfaces as "unknown"/"internal-error" with "Failed to connect".
      final message = error.message?.toLowerCase() ?? '';
      if (message.contains('failed to connect') ||
          message.contains('unable to resolve host') ||
          message.contains('timeout')) {
        return _networkMessage;
      }
      return _genericMessage;
    default:
      return _genericMessage;
  }
}

const _networkMessage =
    'Can\'t reach the server. Check your connection (and that the emulators are running).';
const _genericMessage = 'Something went wrong. Please try again.';
