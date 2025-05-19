import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool get isAuthenticated => _isAuthenticated;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider() {
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final token = await _secureStorage.read(key: 'auth_token');
    if (token != null && token.isNotEmpty) {
      _isAuthenticated = true;
      notifyListeners();
      // Get current user info if needed
      // await _getCurrentUser();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.adminLogin(email, password);

      _isAuthenticated = true;
      _currentUser = User(
        id: response['user']['id'],
        name: response['user']['name'],
        email: response['user']['email'],
        isAdmin: true,
        role: UserRole.admin,
        createdAt: DateTime.now(),
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.logout();
      _isAuthenticated = false;
      _currentUser = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
