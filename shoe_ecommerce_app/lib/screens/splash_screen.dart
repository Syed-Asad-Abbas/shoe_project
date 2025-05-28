import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../utils/theme.dart';
import 'home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isLoading = true;
  String _loadingText = "Initializing...";

  @override
  void initState() {
    super.initState();
    _preloadData();
  }

  Future<void> _preloadData() async {
    try {
      // Wait minimum amount of time to show splash screen
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;
      setState(() {
        _loadingText = "Checking authentication...";
      });

      // Check if user is authenticated
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.checkAuthStatus();

      // Preload product data
      if (mounted) {
        setState(() {
          _loadingText = "Loading products from local server...";
        });
        final productProvider =
            Provider.of<ProductProvider>(context, listen: false);
        await productProvider.initialize();
      }

      // Ensure we show splash for at least 2 seconds
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      _navigateToNextScreen();
    } catch (e) {
      debugPrint('Error during preloading: $e');
      if (mounted) {
        setState(() {
          _loadingText = "Error: $e";
        });
        await Future.delayed(const Duration(seconds: 2));
      }
      // Still navigate to next screen even if there was an error
      if (mounted) {
        _navigateToNextScreen();
      }
    }
  }

  void _navigateToNextScreen() {
    // Check if user is authenticated and navigate accordingly
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Navigate based on authentication status
    if (authProvider.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo or app icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.shopping_bag,
                size: 80,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 24),

            // App name
            const Text(
              'Shoe Shop',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            // Tagline
            const Text(
              'Walk in Style',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 40),

            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),

            const SizedBox(height: 16),

            // Loading status
            Text(
              _loadingText,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
