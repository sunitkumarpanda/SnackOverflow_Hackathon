import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ─── Get Current User ──────────────────────────────────────────────────────
  User? getCurrentUser() => _auth.currentUser;

  // ─── Email/Password Login ──────────────────────────────────────────────────
  Future<User?> login(String email, String password) async {
    try {
      final credential = await _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception(
                'Network is slow, please try again.'),
          );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } on Exception catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ─── Email/Password Signup ─────────────────────────────────────────────────
  Future<User?> signup(String email, String password) async {
    try {
      final credential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception(
                'Network is slow, please try again.'),
          );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } on Exception catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ─── Google Sign-In ────────────────────────────────────────────────────────
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the Google sign-in
        throw Exception('Google sign-in was cancelled.');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth
          .signInWithCredential(credential)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception(
                'Network is slow, please try again.'),
          );

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } on Exception catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ─── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (_) {
      // Silently handle any sign-out errors
    }
  }

  // ─── Error Handler ─────────────────────────────────────────────────────────
  Exception _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No account found with this email.');
      case 'wrong-password':
        return Exception('Incorrect password. Please try again.');
      case 'invalid-email':
        return Exception('Please enter a valid email address.');
      case 'user-disabled':
        return Exception('This account has been disabled.');
      case 'email-already-in-use':
        return Exception('An account already exists with this email.');
      case 'weak-password':
        return Exception('Password must be at least 6 characters.');
      case 'too-many-requests':
        return Exception('Too many attempts. Please try again later.');
      case 'network-request-failed':
        return Exception('Network error. Please check your connection.');
      case 'invalid-credential':
        return Exception('Invalid credentials. Please check and try again.');
      default:
        return Exception('Authentication failed. Please try again.');
    }
  }
}
