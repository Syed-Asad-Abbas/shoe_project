import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoogleSignInTest extends StatefulWidget {
  const GoogleSignInTest({Key? key}) : super(key: key);

  @override
  State<GoogleSignInTest> createState() => _GoogleSignInTestState();
}

class _GoogleSignInTestState extends State<GoogleSignInTest> {
  String _status = 'Not signed in';
  bool _isLoading = false;

  Future<void> _testGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _status = 'Attempting to sign in...';
    });

    try {
      // Print debug info
      debugPrint('Starting Google Sign In test');

      // Initialize GoogleSignIn with minimal scopes
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email'],
      );

      debugPrint('Calling googleSignIn.signIn()');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() {
          _status = 'Sign in canceled by user';
          _isLoading = false;
        });
        return;
      }

      debugPrint('Google user signed in: ${googleUser.email}');

      // Get auth details
      debugPrint('Getting auth details');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Debug tokens
      debugPrint('AccessToken exists: ${googleAuth.accessToken != null}');
      debugPrint('IdToken exists: ${googleAuth.idToken != null}');

      // Create Firebase credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      debugPrint('Signing in to Firebase');
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      debugPrint('Firebase user signed in: ${userCredential.user?.email}');

      setState(() {
        _status = 'Signed in as: ${userCredential.user?.displayName}';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error during Google sign in: $e');
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Sign-In Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _status,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _testGoogleSignIn,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Test Google Sign-In'),
            ),
          ],
        ),
      ),
    );
  }
}
