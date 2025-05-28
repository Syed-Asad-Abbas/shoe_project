import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';
import 'package:http/http.dart' as http;
import '../utils/network_utils.dart';
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;
  String? _token;

  final ApiService _apiService = ApiService();
  final FirebaseService _firebaseService = FirebaseService();

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;

  AuthProvider() {
    debugPrint('AuthProvider initializing...');

    // Listen to Firebase auth state changes
    _firebaseService.authStateChanges
        .listen((firebase_auth.User? firebaseUser) {
      debugPrint(
          'Firebase auth state changed: user ${firebaseUser != null ? 'exists' : 'is null'}');

      if (firebaseUser == null) {
        // If Firebase user is null and we were authenticated, logout
        if (_isAuthenticated) {
          debugPrint(
              'Firebase user is null but we were authenticated - logging out');
          logout();
        }
      } else {
        // If Firebase user exists, handle authentication
        debugPrint('Firebase user exists - handling authentication');
        _handleFirebaseAuth(firebaseUser);
      }
    });

    // Initial auth check
    debugPrint('Running initial auth check');
    checkAuthStatus();
  }

  Future<void> checkAuthStatus({bool forceRefresh = false}) async {
    debugPrint(
        'Checking authentication status... (forceRefresh: $forceRefresh)');
    _setLoading(true);

    try {
      // Check if user is logged in with Firebase
      final firebaseUser = _firebaseService.getCurrentUser();
      debugPrint(
          'Firebase current user: ${firebaseUser != null ? 'exists' : 'null'}');

      if (firebaseUser != null) {
        debugPrint('Firebase user exists, handling auth');
        await _handleFirebaseAuth(firebaseUser);
        return;
      }

      // Check if logged in via SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      debugPrint('SharedPreferences isLoggedIn: $isLoggedIn');

      if (isLoggedIn) {
        // If SharedPreferences says we're logged in but Firebase doesn't, try to load user from API
        final token = await _apiService.getToken();
        debugPrint('API token: ${token != null ? 'exists' : 'null'}');

        if (token != null) {
          try {
            debugPrint(
                'Getting user profile from API (forceRefresh: $forceRefresh)');
            final user =
                await _apiService.getUserProfile(forceRefresh: forceRefresh);
            _user = user;
            _isAuthenticated = true;
            debugPrint('User profile loaded, authenticated: $_isAuthenticated');
          } catch (e) {
            // If we can't load the user profile, consider the user logged out
            debugPrint('Failed to load user profile: $e');
            await logout();
          }
        } else {
          // If no token is available, log the user out
          debugPrint('No token available, logging out');
          await logout();
        }
        return;
      }

      // Check traditional login via token
      final token = await _apiService.getToken();
      debugPrint('Checking API token: ${token != null ? 'exists' : 'null'}');

      if (token != null) {
        debugPrint(
            'Token exists, loading user profile (forceRefresh: $forceRefresh)');
        final user =
            await _apiService.getUserProfile(forceRefresh: forceRefresh);
        _user = user;
        _isAuthenticated = true;
        debugPrint('User authenticated via API token');
      } else {
        debugPrint('No token found, user is not authenticated');
      }
    } catch (e) {
      debugPrint('Auth status check error: $e');
      _isAuthenticated = false;
      _error = 'Failed to verify authentication status';
      await logout();
    } finally {
      _setLoading(false);
      debugPrint(
          'Auth check completed. isAuthenticated: $_isAuthenticated, user: ${_user?.name ?? 'null'}');
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      // Firebase registration
      await _firebaseService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _handleFirebaseError(e);
      return false;
    } catch (e) {
      _error = 'Registration failed: ${e.toString()}';
      debugPrint('Registration error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('Attempting login with email: $email');
      final response = await _apiService.login(email, password);

      debugPrint('Login response: $response');

      final token = response['token'];
      final user = User.fromJson(response['user']);

      // Save auth data locally
      _token = token;
      _user = user;
      _isAuthenticated = true;

      // For demo purposes, hardcode a valid token if the server doesn't provide one
      if (_token == null || _token!.isEmpty) {
        debugPrint('No token received from server, using mock token');
        _token =
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6InVzZXIxMjMiLCJlbWFpbCI6ImRlbW9AZXhhbXBsZS5jb20iLCJyb2xlIjoiY3VzdG9tZXIiLCJpYXQiOjE2OTAyMzY4MDAsImV4cCI6MTY5MDg0MTYwMH0.dE1JnvJRore9j1dw7RJ9KWU1BtIVIW8B9mhMRoO3nHc';
      }

      // Save token to shared prefs
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('token', _token!);
      prefs.setString('user', jsonEncode(_user!.toJson()));
      prefs.setBool('isLoggedIn', true);

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Login error: $e');

      // Demo mode - provide a fallback login for testing
      if (email == 'test@example.com' && password == 'password') {
        debugPrint('Using mock login for test user');
        _token =
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6InVzZXIxMjMiLCJlbWFpbCI6ImRlbW9AZXhhbXBsZS5jb20iLCJyb2xlIjoiY3VzdG9tZXIiLCJpYXQiOjE2OTAyMzY4MDAsImV4cCI6MTY5MDg0MTYwMH0.dE1JnvJRore9j1dw7RJ9KWU1BtIVIW8B9mhMRoO3nHc';
        _user = User(
          id: 'user123',
          name: 'Test User',
          email: email,
          isAdmin: false,
        );
        _isAuthenticated = true;

        // Save mock auth data
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('token', _token!);
        prefs.setString('user', jsonEncode(_user!.toJson()));
        prefs.setBool('isLoggedIn', true);

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = 'Login failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _error = null;

    try {
      // Check internet connectivity first
      final hasConnection = await NetworkUtils.hasInternetConnection();
      if (!hasConnection) {
        _error =
            'No internet connection. Please check your network settings and try again.';
        return false;
      }

      // Use retry with backoff for network stability
      final user = await NetworkUtils.retryWithBackoff(
        function: () => _firebaseService.signInWithGoogle(),
        maxRetries: 3,
        initialDelay: const Duration(seconds: 1),
      );

      if (user != null) {
        await _handleFirebaseAuth(user);
        return true;
      } else {
        _error = 'Failed to sign in with Google';
        return false;
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      _handleFirebaseError(e);
      return false;
    } catch (e) {
      if (e.toString().contains('sign_in_canceled')) {
        _error = 'Google sign-in was canceled';
      } else if (e.toString().contains('ApiException: 10')) {
        _error =
            'SHA-1 certificate fingerprint mismatch. Please check Firebase console configuration.';
      } else if (e.toString().contains('network-request-failed') ||
          e.toString().contains('network error') ||
          e.toString().contains('timeout') ||
          e.toString().contains('connection')) {
        _error = NetworkUtils.getNetworkErrorMessage(e);
      } else {
        _error = 'Google sign-in failed: ${e.toString()}';
      }
      debugPrint('Google sign-in error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _handleFirebaseAuth(firebase_auth.User firebaseUser) async {
    debugPrint(
        'Handling Firebase authentication for user: ${firebaseUser.email}');

    try {
      // Try to log in with backend
      try {
        debugPrint('Attempting to login with backend');
        await _firebaseService.loginWithBackend(firebaseUser);
        debugPrint('Backend login successful');
      } catch (e) {
        // If login fails, try registering
        debugPrint('Backend login failed: $e, attempting registration');
        try {
          await _firebaseService.registerWithBackend(firebaseUser);
          debugPrint('Backend registration successful');
        } catch (e) {
          debugPrint('Error registering with backend: $e');
          // We don't want to throw here - backend failures shouldn't affect Firebase auth
        }
      }

      // Save user info to local storage
      debugPrint('Saving user info to SharedPreferences');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      // Map Firebase user to app user model
      _user = User(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'User',
        email: firebaseUser.email ?? '',
        photoUrl: firebaseUser.photoURL,
      );

      // Set authenticated state to true
      _isAuthenticated = true;
      debugPrint('User authenticated: $_isAuthenticated, user: ${_user?.name}');

      notifyListeners();
    } catch (e) {
      debugPrint('Error handling Firebase auth: $e');
      // Don't rethrow, as we still want to allow Firebase authentication
      // even if backend integration fails
    }
  }

  void _handleFirebaseError(firebase_auth.FirebaseAuthException e) {
    debugPrint('Firebase error code: ${e.code}');

    switch (e.code) {
      case 'user-not-found':
        _error = 'No user found with this email.';
        break;
      case 'wrong-password':
        _error = 'Wrong password provided.';
        break;
      case 'email-already-in-use':
        _error = 'The email address is already in use.';
        break;
      case 'weak-password':
        _error = 'The password provided is too weak.';
        break;
      case 'invalid-email':
        _error = 'The email address is invalid.';
        break;
      case 'user-disabled':
        _error = 'This user account has been disabled.';
        break;
      case 'operation-not-allowed':
        _error = 'This operation is not allowed.';
        break;
      case 'sign_in_canceled':
        _error = 'Sign-in was canceled.';
        break;
      case 'invalid_cert':
        _error =
            'SHA-1 certificate fingerprint mismatch. Please check Firebase console configuration.';
        break;
      case 'network-request-failed':
        _error = NetworkUtils.getNetworkErrorMessage(e);
        break;
      default:
        _error = e.message ?? 'An unknown error occurred.';
    }
  }

  Future<void> logout() async {
    _setLoading(true);

    try {
      await _firebaseService.signOut();

      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('isLoggedIn');

      _user = null;
      _isAuthenticated = false;
      _error = null;
    } catch (e) {
      debugPrint('Logout error: $e');
      _error = 'Failed to logout: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _error = null;

    try {
      await _firebaseService.resetPassword(email);
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _handleFirebaseError(e);
      return false;
    } catch (e) {
      _error = 'Password reset failed: ${e.toString()}';
      debugPrint('Password reset error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile() async {
    try {
      final updatedUser = await _apiService.getUserProfile();
      _user = updatedUser;
      notifyListeners();
    } catch (e) {
      debugPrint('Update profile error: $e');
      _error = 'Failed to update profile: ${e.toString()}';
    }
  }

  // Toggle a product as favorite
  Future<void> toggleFavorite(String productId) async {
    if (!isAuthenticated || _user == null) {
      throw Exception('User not authenticated');
    }

    _setLoading(true);

    try {
      // Simulate API call since we don't have an actual toggleFavorite API method
      await Future.delayed(const Duration(milliseconds: 500));

      // Update the user's favorites list
      final updatedFavorites = List<String>.from(_user!.favorites);

      if (updatedFavorites.contains(productId)) {
        updatedFavorites.remove(productId);
      } else {
        updatedFavorites.add(productId);
      }

      // Create an updated user with the new favorites list
      _user = User(
        id: _user!.id,
        name: _user!.name,
        email: _user!.email,
        address: _user!.address,
        phone: _user!.phone,
        favorites: updatedFavorites,
        isAdmin: _user!.isAdmin,
      );
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      _error = 'Failed to update favorites: ${e.toString()}';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Add a method to refresh user profile
  Future<void> refreshUserProfile() async {
    debugPrint('Refreshing user profile');
    if (_isAuthenticated) {
      try {
        final user = await _apiService.getUserProfile(forceRefresh: true);
        _user = user;
        notifyListeners();
        debugPrint('User profile refreshed successfully: ${_user?.name}');
      } catch (e) {
        debugPrint('Error refreshing user profile: $e');
        _error = 'Failed to refresh profile: ${e.toString()}';
      }
    } else {
      debugPrint('Cannot refresh profile: user not authenticated');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
