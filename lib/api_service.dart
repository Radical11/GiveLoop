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
      return 'http://192.168.0.117:8000/api';
    }
    if (Platform.isIOS) {
      return 'http://127.0.0.1:8000/api';
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
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          print('DIO REQUEST: ${options.method} ${options.uri}');
          handler.next(options);
        },
        onError: (e, handler) {
          print('DIO ERROR: ${e.type} -> ${e.message}');
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
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('Login Failed: ${e.response?.data}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register/',
        data: {
          'username': username,
          'email': email.trim(), // Ensure no leading/trailing spaces
          'password': password,
        },
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      // This helper will print the exact validation error in your console
      print('DJANGO VALIDATION DETAIL: ${e.response?.data}');
      rethrow;
    }
  }

  Future<void> saveToken(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  Future<List<dynamic>> getNeeds() async {
    final response = await _dio.get('/needs/');
    return List<dynamic>.from(response.data as List);
  }

  Future<Map<String, dynamic>> pledge({
    required int needId,
    required String category,
    required int quantity,
  }) async {
    final response = await _dio.post(
      '/donations/pledge/',
      data: {'need_id': needId, 'category': category, 'quantity': quantity},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<dynamic>> getLeaderboard() async {
    final response = await _dio.get('/users/leaderboard/');
    return List<dynamic>.from(response.data as List);
  }
}
