import 'package:flutter/material.dart';
import '../api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  bool _isLoading = false;
  String? _token;
  String? _userId;
  String? _username;
  DateTime? _expiryDate;
  bool get isLoggedIn => _token != null;
  bool get isLoading => _isLoading;
  String? get username => _username;

  Future<bool> login(String usernameOrEmail, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      print('LOGIN START');

      final response = await _api.login(usernameOrEmail, password);
      print('LOGIN RESPONSE: $response');

      _username = response['user']?['username'] ?? usernameOrEmail;
      _userId = response['user']?['id']?.toString();

      await _api.saveToken(response['access'], response['refresh']);
      _token = response['access'];
      _expiryDate = DateTime.now().add(Duration(hours: 24));

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
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      await _api.register(username: username, email: email, password: password);

      final loginData = await _api.login(username, password);
      final accessToken = loginData['access'] as String?;
      final refreshToken = loginData['refresh'] as String?;

      _username = username;

      if (accessToken != null && refreshToken != null) {
        await _api.saveToken(accessToken, refreshToken);
        _token = accessToken;
        return true;
      } else {
        print('No tokens in login response after register');
        return false;
      }
    } catch (e) {
      print('Register+login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _api.logout();
    _token = null;
    _userId = null;
    _username = null;
    _expiryDate = null;
    notifyListeners();
    print('LOGOUT');
  }
}
