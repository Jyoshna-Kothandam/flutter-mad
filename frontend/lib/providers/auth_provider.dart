import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isAuthenticated = false;
  String _role = 'citizen';
  String _username = '';
  bool _isLoading = false;

  bool get isAuthenticated => _isAuthenticated;
  String get role => _role;
  String get username => _username;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      _isAuthenticated = true;
      _role = prefs.getString('role') ?? 'citizen';
      _username = prefs.getString('username') ?? '';
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    final data = await _apiService.login(username, password);
    _isLoading = false;
    if (data != null) {
      _isAuthenticated = true;
      _role = data['role'];
      _username = data['username'];
      notifyListeners();
      return true;
    }
    notifyListeners();
    return false;
  }

  Future<bool> register(String username, String email, String password, String role) async {
    _isLoading = true;
    notifyListeners();
    final success = await _apiService.register(username, email, password, role);
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> logout() async {
    await _apiService.logout();
    _isAuthenticated = false;
    _role = 'citizen';
    _username = '';
    notifyListeners();
  }
}
