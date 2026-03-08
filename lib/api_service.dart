import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api';
    }
    if (Platform.isIOS) {
      return 'http://10.0.2.2:8000/api';
    }
    if (Platform.isMacOS) {
      return 'http://127.0.0.1:8000/api';
    }
    return 'http://127.0.0.1:8000/api';
  }

  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('access_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          print('DIO: ${options.method} ${options.uri.path}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          print('DIO OK: ${response.statusCode}');
          handler.next(response);
        },
        onError: (e, handler) {
          print('DIO ERROR [${e.response?.statusCode}]: ${e.response?.data}');
          handler.next(e);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> login(
    String usernameOrEmail,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/login/',
        data: {'username': usernameOrEmail, 'password': password},
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      print('LOGIN ERROR: ${e.response?.data ?? e.message}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      print('API REGISTER BODY: username=$username, email=$email');
      final response = await _dio.post(
        '/auth/register/',
        data: {
          'username': username,
          'email': email.trim(),
          'password': password,
        },
      );
      print('REGISTER SUCCESS: ${response.data}');
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      print('REGISTER ERROR: ${e.response?.data ?? e.message}');
      rethrow;
    }
  }

  Future<void> saveToken(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    print('Tokens saved');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    print('Logged out');
  }

  Future<List<dynamic>> getNeeds() async {
    try {
      final response = await _dio.get('/needs/');
      return List<dynamic>.from(response.data['results'] ?? []);
    } on DioException catch (e) {
      print('GET NEEDS ERROR: ${e.response?.data ?? e.message}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> pledge({
    required int needId,
    required String category,
    required int quantity,
  }) async {
    print('Pledging: needId=$needId, category="$category", qty=$quantity');
    try {
      final response = await _dio.post(
        '/donations/pledge/',
        data: {'need_request': needId, 'category': category, 'qty': quantity},
      );
      print('Pledge created: ${response.data}');
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      print('PLEDGE ERROR: ${e.response?.data ?? e.message}');
      rethrow;
    }
  }

  Future<List<dynamic>> getLeaderboard() async {
    try {
      final response = await _dio.get('/users/leaderboard/');
      return List<dynamic>.from(response.data as List);
    } on DioException catch (e) {
      print('LEADERBOARD ERROR: ${e.response?.data ?? e.message}');
      rethrow;
    }
  }
}
