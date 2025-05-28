import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// A widget to test Firebase Authentication with error handling
class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({Key? key}) : super(key: key);

  @override
  _FirebaseTestScreenState createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _status = 'Ready to test Firebase';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the entire build in a try/catch to prevent UI crashes
    try {
      final authProvider = Provider.of<AuthProvider>(context);

      return Scaffold(
        appBar: AppBar(
          title: const Text('Firebase Test'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Firebase Connection Test',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Status display
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _status,
                    style: TextStyle(
                      color: _status.contains('Error') ||
                              _status.contains('Failed')
                          ? Colors.red
                          : _status.contains('Success')
                              ? Colors.green
                              : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Authentication status
                Text(
                    'Current Auth Status: ${authProvider.isAuthenticated ? 'Logged In' : 'Logged Out'}'),
                if (authProvider.error != null)
                  Text('Error: ${authProvider.error}',
                      style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 20),

                // Email input
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),

                // Password input
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 20),

                // Test buttons
                ElevatedButton(
                  onPressed: () => _testAnonymousAuth(),
                  child: const Text('Test Firebase Connection'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => _testEmailSignUp(context),
                  child: const Text('Test Email Sign Up'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => _testEmailSignIn(context),
                  child: const Text('Test Email Sign In'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => _testGoogleSignIn(context),
                  child: const Text('Test Google Sign In'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => _testSignOut(context),
                  child: const Text('Test Sign Out'),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      // Fallback UI if there's an error in the provider
      return Scaffold(
        appBar: AppBar(
          title: const Text('Firebase Test'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading Firebase Test: $e',
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _testAnonymousAuth() async {
    try {
      setState(() {
        _status = 'Testing Firebase connection...';
      });

      // Simply check if we can get the Firebase instance
      final auth = firebase.FirebaseAuth.instance;
      try {
        final result =
            await auth.fetchSignInMethodsForEmail('test@example.com');
        setState(() {
          _status = 'Success! Firebase is connected properly.';
        });
      } catch (e) {
        setState(() {
          _status = 'Firebase is initialized but API call failed: $e';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error: Firebase connection failed: $e';
      });
    }
  }

  Future<void> _testEmailSignUp(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _status = 'Error: Please enter email and password';
      });
      return;
    }

    setState(() {
      _status = 'Attempting to create account...';
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(email, email, password);

    setState(() {
      _status = success
          ? 'Success! Account created.'
          : 'Failed to create account: ${authProvider.error}';
    });
  }

  Future<void> _testEmailSignIn(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _status = 'Error: Please enter email and password';
      });
      return;
    }

    setState(() {
      _status = 'Attempting to sign in...';
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(email, password);

    setState(() {
      _status = success
          ? 'Success! Signed in with email.'
          : 'Failed to sign in: ${authProvider.error}';
    });
  }

  Future<void> _testGoogleSignIn(BuildContext context) async {
    setState(() {
      _status = 'Attempting Google sign in...';
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithGoogle();

    setState(() {
      _status = success
          ? 'Success! Signed in with Google.'
          : 'Failed to sign in with Google: ${authProvider.error}';
    });
  }

  Future<void> _testSignOut(BuildContext context) async {
    setState(() {
      _status = 'Signing out...';
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    setState(() {
      _status = 'Signed out successfully.';
    });
  }
}
