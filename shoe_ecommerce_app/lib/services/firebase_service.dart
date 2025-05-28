import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';
import '../utils/network_utils.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  // Get current Firebase user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Email/Password Sign Up
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // After Firebase auth, register with backend
      if (userCredential.user != null) {
        await registerWithBackend(userCredential.user!);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase signup error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error during signup: $e');
      rethrow;
    }
  }

  // Email/Password Sign In
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // After Firebase auth, login with backend
      if (userCredential.user != null) {
        await loginWithBackend(userCredential.user!);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase login error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error during login: $e');
      rethrow;
    }
  }

  // Google Sign In
  Future<User?> signInWithGoogle() async {
    // First check if we can reach Firebase
    if (!await NetworkUtils.canReachFirebase()) {
      throw FirebaseAuthException(
        code: 'network-request-failed',
        message:
            'Cannot reach Firebase servers. Please check your internet connection.',
      );
    }

    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'sign_in_canceled',
          message: 'Google sign in was canceled',
        );
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      debugPrint('Google Auth accessToken: ${googleAuth.accessToken != null}');
      debugPrint('Google Auth idToken: ${googleAuth.idToken != null}');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      try {
        // Sign in to Firebase with the Google credential with timeout handling
        UserCredential? userCredential;

        try {
          userCredential = await _auth
              .signInWithCredential(credential)
              .timeout(const Duration(seconds: 20));

          // After Firebase auth, handle backend integration
          if (userCredential.user != null) {
            try {
              await loginWithBackend(userCredential.user!);
            } catch (e) {
              // If login fails, try registering as a new user
              try {
                await registerWithBackend(userCredential.user!);
              } catch (e) {
                // Don't throw on backend failure
                debugPrint('Backend registration failed: $e');
              }
            }
            return userCredential.user;
          }
          return null;
        } catch (e) {
          // Handle specific PigeonUserDetails error from firebase_auth package
          if (e.toString().contains('PigeonUserDetails')) {
            // This is a known issue with some versions of the Firebase Auth plugin
            // The authentication likely succeeded but the return value parsing failed

            // Use getCurrentUser instead
            final currentUser = _auth.currentUser;
            if (currentUser != null) {
              // Still attempt backend integration
              try {
                await loginWithBackend(currentUser);
              } catch (loginError) {
                try {
                  await registerWithBackend(currentUser);
                } catch (registerError) {
                  // Silently ignore backend errors
                  debugPrint('Backend auth failed: $registerError');
                }
              }
              return currentUser;
            }
          }
          rethrow;
        }
      } catch (e) {
        debugPrint('Error during Firebase signInWithCredential: $e');

        // If we get API Exception with code 10, it's likely a SHA-1 certificate issue
        if (e.toString().contains('ApiException: 10')) {
          throw FirebaseAuthException(
            code: 'invalid_cert',
            message:
                'SHA-1 certificate fingerprint mismatch. Please check Firebase console configuration.',
          );
        }

        // Identify if it's a network error
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('network') ||
            errorStr.contains('timeout') ||
            errorStr.contains('connection')) {
          throw FirebaseAuthException(
            code: 'network-request-failed',
            message: NetworkUtils.getNetworkErrorMessage(e),
          );
        }

        rethrow;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Google sign-in error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();

      // Clear token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  // Register Firebase user with backend
  Future<void> registerWithBackend(User firebaseUser) async {
    try {
      final idToken = await firebaseUser.getIdToken();

      final response = await http
          .post(
            Uri.parse('${Constants.apiUrl}/auth/register/firebase'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'token': idToken,
              'name': firebaseUser.displayName ?? '',
              'email': firebaseUser.email ?? '',
              'photoUrl': firebaseUser.photoURL ?? '',
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('user', jsonEncode(data['user']));
      } else {
        debugPrint(
            'Backend registration failed: ${response.statusCode} - ${response.body}');
        // Don't throw - we want to continue with Firebase auth even if backend fails
      }
    } catch (e) {
      debugPrint('Error registering with backend: $e');
      // Don't rethrow - we want Firebase authentication to succeed
      // even if backend registration fails
    }
  }

  // Login Firebase user with backend
  Future<void> loginWithBackend(User firebaseUser) async {
    try {
      final idToken = await firebaseUser.getIdToken();

      final response = await http
          .post(
            Uri.parse('${Constants.apiUrl}/auth/login/firebase'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'token': idToken}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('user', jsonEncode(data['user']));
      } else {
        throw Exception('Failed to login: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error logging in with backend: $e');
      // Don't rethrow - we'll try to register instead
      // This allows the app to work without the backend available
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase reset password error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error resetting password: $e');
      rethrow;
    }
  }
}
