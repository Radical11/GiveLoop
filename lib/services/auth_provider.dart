import 'package:flutter/material.dart';
import '../api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  bool _isLoading = false;
  String? _token;

  bool get isLoggedIn => _token != null;
  bool get isLoading => _isLoading;

  Future<bool> login(String emailOrUsername, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      print('AuthProvider.login -> start');

      final response = await _api.login(emailOrUsername, password);
      print('AuthProvider.login -> response: $response');

      await _api.saveToken(response['access'], response['refresh']);
      _token = response['access'];

      _isLoading = false;
      notifyListeners();
      print('AuthProvider.login -> success, token set');
      return true;
    } catch (e) {
      print('AuthProvider.login -> ERROR: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String password,
    required String email,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _api.register(
        username: username,
        password: password,
        email: email,
      );

      await _api.saveToken(response['access'], response['refresh']);
      _token = response['access'];

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _api.logout();
    _token = null;
    notifyListeners();
  }
}
