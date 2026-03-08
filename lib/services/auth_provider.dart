import 'package:flutter/material.dart';
import '../api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  bool _isLoading = false;
  String? _token;

  bool get isLoggedIn => _token != null;
  bool get isLoading => _isLoading;

  Future<bool> login(String usernameOrEmail, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      print('LOGIN START');

      final response = await _api.login(usernameOrEmail, password);
      print('LOGIN RESPONSE: $response');

      await _api.saveToken(response['access'], response['refresh']);
      _token = response['access'];

      _isLoading = false;
      notifyListeners();
      print('LOGIN SUCCESS');
      return true;
    } catch (e) {
      print('LOGIN ERROR: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      print('🔐 REGISTER START: $name / $email');

      final response = await _api.register(
        name: name,
        email: email,
        password: password,
      );

      print('REGISTER RESPONSE: $response');
      await _api.saveToken(response['access'], response['refresh']);
      _token = response['access'];

      _isLoading = false;
      notifyListeners();
      print('REGISTER SUCCESS');
      return true;
    } catch (e) {
      print('REGISTER ERROR: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _api.logout();
    _token = null;
    notifyListeners();
    print('LOGOUT');
  }
}
