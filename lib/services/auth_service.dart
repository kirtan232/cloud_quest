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
      return 'Network error. Check your connection (and that the emulators are running).';
    default:
      return 'Something went wrong. Please try again.';
  }
}
