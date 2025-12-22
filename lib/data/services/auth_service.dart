import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Email Sign Up
  static Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      await userCredential.user?.updateDisplayName(displayName.trim());
      await userCredential.user?.sendEmailVerification();

      return AuthResult(
        success: true,
        user: userCredential.user,
        message: 'Account created! Check email for verification.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: _getSignUpError(e.code));
    } catch (e) {
      return AuthResult(success: false, message: 'Something went wrong.');
    }
  }

  // Email Login
  static Future<AuthResult> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return AuthResult(
        success: true,
        user: userCredential.user,
        message: 'Welcome back!',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: _getLoginError(e.code));
    } catch (e) {
      return AuthResult(success: false, message: 'Login failed.');
    }
  }

  // Google Sign-In
  static Future<AuthResult> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          return AuthResult(success: false, message: 'Cancelled.', cancelled: true);
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      return AuthResult(
        success: true,
        user: userCredential.user,
        message: 'Signed in with Google!',
      );
    } catch (e) {
      if (e.toString().contains('canceled')) {
        return AuthResult(success: false, message: 'Cancelled.', cancelled: true);
      }
      return AuthResult(success: false, message: 'Google Sign-In failed.');
    }
  }

  // Apple Sign-In
  static Future<AuthResult> signInWithApple() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        final appleProvider = OAuthProvider('apple.com');
        appleProvider.addScope('email');
        appleProvider.addScope('name');
        userCredential = await _auth.signInWithPopup(appleProvider);
      } else {
        final rawNonce = _generateNonce();
        final nonce = _sha256ofString(rawNonce);

        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: nonce,
        );

        final oauthCredential = OAuthProvider("apple.com").credential(
          idToken: appleCredential.identityToken,
          rawNonce: rawNonce,
        );

        userCredential = await _auth.signInWithCredential(oauthCredential);

        if (appleCredential.givenName != null) {
          final displayName = '${appleCredential.givenName} ${appleCredential.familyName ?? ''}'.trim();
          await userCredential.user?.updateDisplayName(displayName);
        }
      }

      return AuthResult(
        success: true,
        user: userCredential.user,
        message: 'Signed in with Apple!',
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return AuthResult(success: false, message: 'Cancelled.', cancelled: true);
      }
      return AuthResult(success: false, message: 'Apple Sign-In failed.');
    } catch (e) {
      return AuthResult(success: false, message: 'Apple Sign-In failed.');
    }
  }

  // Password Reset
  static Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult(success: true, message: 'Reset email sent!');
    } catch (e) {
      return AuthResult(success: false, message: 'Failed to send reset email.');
    }
  }

  // Sign Out
  static Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      try { await GoogleSignIn().signOut(); } catch (_) {}
    }
  }

  static String _getSignUpError(String code) {
    switch (code) {
      case 'weak-password': return 'Password is too weak.';
      case 'email-already-in-use': return 'Email already in use.';
      case 'invalid-email': return 'Invalid email address.';
      default: return 'Sign up failed.';
    }
  }

  static String _getLoginError(String code) {
    switch (code) {
      case 'user-not-found': return 'No user found.';
      case 'wrong-password': return 'Wrong password.';
      case 'invalid-email': return 'Invalid email.';
      case 'user-disabled': return 'Account disabled.';
      case 'too-many-requests': return 'Too many attempts.';
      default: return 'Login failed.';
    }
  }
}

class AuthResult {
  final bool success;
  final User? user;
  final String message;
  final bool cancelled;

  AuthResult({
    required this.success,
    this.user,
    required this.message,
    this.cancelled = false,
  });
}
